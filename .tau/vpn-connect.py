#!/usr/bin/env python3
"""
TAU VPN Connection Script for Headless VMs

Automates GlobalProtect VPN connection using SAML authentication via playwright.

Requirements:
    sudo apt install openconnect
    pip install playwright && playwright install chromium
    # Install gpclient from https://github.com/yuezk/GlobalProtect-openconnect/releases

Usage:
    ./vpn-connect.py USERNAME PASSWORD OTP

    # Or with environment variables:
    export TAU_USERNAME=galaharoni
    export TAU_PASSWORD=mypassword
    ./vpn-connect.py --otp 123456
"""

import argparse
import asyncio
import base64
import os
import re
import subprocess
import sys


async def complete_saml_auth(auth_url: str, username: str, password: str, otp: str) -> str | None:
    """Complete SAML authentication via playwright and return the callback URL."""
    from playwright.async_api import async_playwright

    callback_url = None

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(ignore_https_errors=True)
        page = await context.new_page()

        def handle_request(request):
            nonlocal callback_url
            if 'globalprotectcallback' in request.url:
                callback_url = request.url
                print(f"[+] Captured callback")

        page.on('request', handle_request)

        print(f"[*] Opening auth URL...")
        await page.goto(auth_url)

        # Wait for SAML redirect to IdP
        for _ in range(20):
            await asyncio.sleep(1)
            if 'nidp.tau.ac.il' in page.url:
                print("[*] Reached IdP login page")
                break

        # Fill credentials
        print("[*] Entering credentials...")
        uf = await page.query_selector('input[placeholder="Username"]')
        pf = await page.query_selector('input[placeholder="Password"]')
        if uf and pf:
            await uf.fill(username)
            await pf.fill(password)
            await pf.press('Enter')
            await asyncio.sleep(5)
        else:
            print("[-] Could not find login fields")
            await browser.close()
            return None

        # Fill 2FA
        print("[*] Entering 2FA code...")
        otp_field = await page.query_selector('input[placeholder*="code"], input[placeholder*="device"]')
        if otp_field:
            await otp_field.fill(otp)
            await otp_field.press('Enter')

            # Wait for callback
            for _ in range(30):
                await asyncio.sleep(1)
                if callback_url:
                    break
        else:
            print("[-] Could not find 2FA field")

        await browser.close()

    return callback_url


def extract_cookie(callback_url: str) -> tuple[str, str] | tuple[None, None]:
    """Extract prelogin-cookie and username from callback URL."""
    if not callback_url or not callback_url.startswith('globalprotectcallback:'):
        return None, None

    data = callback_url.replace('globalprotectcallback:', '')
    try:
        decoded = base64.b64decode(data).decode('utf-8')
        cookie_match = re.search(r'<prelogin-cookie>([^<]+)</prelogin-cookie>', decoded)
        user_match = re.search(r'<saml-username>([^<]+)</saml-username>', decoded)

        if cookie_match:
            cookie = cookie_match.group(1)
            username = user_match.group(1) if user_match else None
            return cookie, username
    except Exception as e:
        print(f"[-] Failed to decode callback: {e}")

    return None, None


def start_gpclient(username: str) -> tuple[subprocess.Popen, str | None]:
    """Start gpclient in gateway mode and return the auth URL."""
    print("[*] Starting gpclient in gateway mode...")

    proc = subprocess.Popen(
        ['sudo', 'gpclient', 'connect', 'vpn.tau.ac.il', '--as-gateway', '--browser', 'remote', '-u', username],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    auth_url = None
    for _ in range(30):
        line = proc.stdout.readline()
        if 'http://' in line:
            match = re.search(r'(http://[^\s]+)', line)
            if match:
                auth_url = match.group(1)
                print(f"[+] Got auth URL")
                break

    return proc, auth_url


def connect_vpn(cookie: str, username: str) -> bool:
    """Connect to VPN using openconnect with the gateway cookie."""
    print("[*] Connecting with openconnect...")

    cmd = [
        'sudo', 'openconnect',
        '--protocol=gp',
        f'--user={username}',
        '--usergroup=gateway:prelogin-cookie',
        '--passwd-on-stdin',
        'vpn.tau.ac.il'
    ]

    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    proc.stdin.write(cookie + '\n')
    proc.stdin.flush()

    # Read output until connected or error
    connected = False
    for _ in range(40):
        line = proc.stdout.readline()
        if not line:
            break
        line = line.strip()
        if line:
            print(f"    {line}")
        if 'Configured as' in line:
            connected = True
            print("\n[+] VPN CONNECTED!")
            break
        if 'error' in line.lower() and 'tls' not in line.lower():
            print("\n[-] Connection failed")
            break

    return connected


async def main():
    parser = argparse.ArgumentParser(description='Connect to TAU VPN from headless VM')
    parser.add_argument('username', nargs='?', default=os.environ.get('TAU_USERNAME'),
                        help='TAU username (or set TAU_USERNAME env var)')
    parser.add_argument('password', nargs='?', default=os.environ.get('TAU_PASSWORD'),
                        help='TAU password (or set TAU_PASSWORD env var)')
    parser.add_argument('otp', nargs='?', help='Google Authenticator OTP code')
    parser.add_argument('--otp', dest='otp_flag', help='OTP code (alternative flag)')

    args = parser.parse_args()

    username = args.username
    password = args.password
    otp = args.otp or args.otp_flag

    if not username or not password:
        print("Error: Username and password required")
        print("  Set TAU_USERNAME and TAU_PASSWORD env vars, or pass as arguments")
        sys.exit(1)

    if not otp:
        otp = input("Enter 2FA code: ").strip()

    # Step 1: Start gpclient to get auth URL
    gpclient_proc, auth_url = start_gpclient(username)

    if not auth_url:
        print("[-] Failed to get auth URL from gpclient")
        gpclient_proc.terminate()
        sys.exit(1)

    # Step 2: Complete SAML auth
    callback_url = await complete_saml_auth(auth_url, username, password, otp)
    gpclient_proc.terminate()

    if not callback_url:
        print("[-] Failed to complete SAML authentication")
        sys.exit(1)

    # Step 3: Extract cookie
    cookie, saml_username = extract_cookie(callback_url)

    if not cookie:
        print("[-] Failed to extract cookie from callback")
        sys.exit(1)

    print(f"[+] Got cookie for {saml_username}")

    # Step 4: Connect with openconnect
    if connect_vpn(cookie, saml_username or username):
        print("[+] VPN session established")
    else:
        sys.exit(1)


if __name__ == '__main__':
    asyncio.run(main())
