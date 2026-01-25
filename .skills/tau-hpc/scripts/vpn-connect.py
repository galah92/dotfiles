#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "playwright",
# ]
# ///
"""
TAU VPN Connection Script for Headless VMs

Automates GlobalProtect VPN connection using SAML authentication via playwright.
Updated for gpclient 2.5.x CLI.

System requirements:
    sudo apt install openconnect
    # Install gpclient from https://github.com/yuezk/GlobalProtect-openconnect/releases

First-time setup:
    uv run --with playwright python -c "from playwright.sync_api import sync_playwright; sync_playwright().start().chromium.launch()"
    # Or: playwright install chromium

Usage:
    uv run vpn-connect.py USERNAME PASSWORD OTP

    # Or with environment variables:
    export TAU_USERNAME=galaharoni
    export TAU_PASSWORD=mypassword
    uv run vpn-connect.py 123456  # just the OTP
"""

import argparse
import asyncio
import base64
import os
import re
import subprocess
import sys


def start_gpclient(username: str) -> tuple[subprocess.Popen, str | None]:
    """Start gpclient in gateway mode and return the local auth URL.

    gpclient 2.5.x creates a local auth server that redirects to the IdP.
    """
    print("[*] Starting gpclient in gateway mode...")

    proc = subprocess.Popen(
        ['sudo', 'gpclient', 'connect', 'vpn.tau.ac.il', '--as-gateway', '--browser', 'remote', '-u', username],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    auth_url = None
    for _ in range(30):
        line = proc.stdout.readline()
        if not line:
            break
        # Look for the local auth server URL (e.g., http://10.x.x.x:PORT/UUID)
        if 'http://' in line:
            match = re.search(r'(http://[0-9.]+:[0-9]+/[a-f0-9-]+)', line)
            if match:
                auth_url = match.group(1)
                print(f"[+] Got auth URL: {auth_url}")
                break

    return proc, auth_url


async def complete_saml_auth(auth_url: str, username: str, password: str, otp: str) -> str | None:
    """Complete SAML authentication via playwright and return the callback URL.

    The callback URL is found in the "click here" link on the auth complete page,
    NOT via request interception.
    """
    from playwright.async_api import async_playwright

    callback_url = None

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(ignore_https_errors=True)
        page = await context.new_page()

        print(f"[*] Opening auth URL...")
        await page.goto(auth_url, wait_until='networkidle', timeout=30000)
        print("[*] At login page")

        # Fill credentials - TAU IdP uses generic input types
        await page.fill('input[type="text"]', username)
        await page.fill('input[type="password"]', password)
        await page.keyboard.press('Enter')
        print("[*] Credentials submitted")

        await asyncio.sleep(3)

        # Fill 2FA - find visible text/tel input
        print("[*] Looking for 2FA field...")
        inputs = await page.query_selector_all('input:visible')
        for inp in inputs:
            inp_type = await inp.get_attribute('type')
            if inp_type in ['text', 'tel', 'number']:
                await inp.fill(otp)
                await inp.press('Enter')
                print("[*] OTP submitted")
                break

        # Wait for auth complete page
        await asyncio.sleep(5)

        # The callback URL is in the "click here" link on the complete page
        # Page shows: "Please click Open GlobalProtect... click here to launch"
        print("[*] Looking for callback link...")
        links = await page.query_selector_all('a')
        for link in links:
            href = await link.get_attribute('href')
            if href and 'globalprotectcallback' in href:
                callback_url = href
                print("[+] Found callback in link")
                break

        # Fallback: check page content
        if not callback_url:
            content = await page.content()
            match = re.search(r'globalprotectcallback:[^\s"<>\']+', content)
            if match:
                callback_url = match.group(0)
                print("[+] Found callback in page content")

        await browser.close()

    return callback_url


def extract_cookie(callback_url: str) -> tuple[str, str] | tuple[None, None]:
    """Extract prelogin-cookie and username from callback URL.

    Callback format: globalprotectcallback:BASE64DATA
    (Note: single colon, not ://)
    """
    if not callback_url:
        return None, None

    # Handle both formats just in case
    if callback_url.startswith('globalprotectcallback://'):
        data = callback_url[len('globalprotectcallback://'):]
    elif callback_url.startswith('globalprotectcallback:'):
        data = callback_url[len('globalprotectcallback:'):]
    else:
        return None, None

    try:
        # Add padding if needed
        padding = 4 - (len(data) % 4)
        if padding != 4:
            data += '=' * padding

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


def connect_vpn(cookie: str, username: str) -> bool:
    """Connect to VPN using openconnect with --background flag.

    The --background flag daemonizes openconnect so it stays running
    after this script exits.
    """
    print("[*] Connecting with openconnect (background mode)...")

    cmd = [
        'sudo', 'openconnect',
        '--protocol=gp',
        f'--user={username}',
        '--usergroup=gateway:prelogin-cookie',
        '--passwd-on-stdin',
        '--background',  # CRITICAL: daemonize so VPN stays up
        'vpn.tau.ac.il'
    ]

    try:
        result = subprocess.run(
            cmd,
            input=cookie + '\n',
            capture_output=True,
            text=True,
            timeout=30
        )

        output = result.stdout + result.stderr
        for line in output.split('\n'):
            if line.strip():
                print(f"    {line}")

        # Check if tunnel interface exists
        check = subprocess.run(['ip', 'addr', 'show', 'tun0'], capture_output=True)
        if check.returncode == 0:
            print("\n[+] VPN CONNECTED! (tun0 interface up)")
            return True
        else:
            print("\n[-] VPN connection may have failed (no tun0)")
            return False

    except subprocess.TimeoutExpired:
        # Timeout is expected with --background since openconnect keeps running
        # Check if it actually connected
        check = subprocess.run(['ip', 'addr', 'show', 'tun0'], capture_output=True)
        if check.returncode == 0:
            print("\n[+] VPN CONNECTED! (tun0 interface up)")
            return True
        return False


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

    # Step 2: Complete SAML auth via playwright
    callback_url = await complete_saml_auth(auth_url, username, password, otp)
    gpclient_proc.terminate()

    if not callback_url:
        print("[-] Failed to complete SAML authentication")
        print("    Check if OTP is still valid (they expire quickly)")
        sys.exit(1)

    # Step 3: Extract cookie from callback
    cookie, saml_username = extract_cookie(callback_url)

    if not cookie:
        print("[-] Failed to extract cookie from callback")
        sys.exit(1)

    print(f"[+] Got cookie for {saml_username}")

    # Step 4: Connect with openconnect (backgrounded)
    if connect_vpn(cookie, saml_username or username):
        print("[+] VPN session established")
        print("[*] To disconnect: sudo pkill openconnect")
    else:
        sys.exit(1)


if __name__ == '__main__':
    asyncio.run(main())
