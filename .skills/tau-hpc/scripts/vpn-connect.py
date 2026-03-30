#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "playwright==1.58.0",
# ]
# ///
"""TAU GlobalProtect VPN connector. Automates SAML auth via headless Chromium.

Usage: uv run vpn-connect.py [USERNAME PASSWORD] OTP
  Credentials default to TAU_USERNAME / TAU_PASSWORD env vars.

Prerequisites: sudo apt install openconnect gpclient
"""

import asyncio
import base64
import os
import re
import subprocess
import sys

SUBMIT_SEL = (
    'input[type="submit"], button[type="submit"],'
    ' input[value="Sign in"], button:has-text("Validate"), input[value="Validate Code"]'
)


async def submit_username_password(page, username: str, password: str) -> None:
    username_fields = [
        'input[type="text"]',
        'input[name="Ecom_User_ID"]',
        'input[placeholder="Username"]',
        'input[placeholder="User name"]',
    ]
    password_fields = [
        'input[type="password"]',
        'input[placeholder="Password"]',
    ]

    for selector in username_fields:
        if await page.query_selector(selector):
            await page.fill(selector, username)
            break
    for selector in password_fields:
        if await page.query_selector(selector):
            await page.fill(selector, password)
            break

    if btn := await page.query_selector(SUBMIT_SEL):
        await btn.click()
    else:
        await page.keyboard.press("Enter")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TAU_SPLIT_SCRIPT = os.path.join(SCRIPT_DIR, "tau-vpnc-split.sh")


def start_gpclient(username: str) -> tuple[subprocess.Popen, str | None]:
    proc = subprocess.Popen(
        [
            "sudo",
            "gpclient",
            "connect",
            "vpn.tau.ac.il",
            "--as-gateway",
            "--browser",
            "remote",
            "-u",
            username,
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    assert proc.stdout is not None
    for _ in range(30):
        line = proc.stdout.readline()
        if not line:
            break
        if m := re.search(r"(http://[0-9.]+:[0-9]+/[a-f0-9-]+)", line):
            return proc, m.group(1)
    return proc, None


async def complete_saml_auth(
    auth_url: str,
    username: str,
    password: str,
    otp: str,
) -> str | None:
    from playwright.async_api import async_playwright  # ty: ignore[unresolved-import]

    subprocess.run(
        [sys.executable, "-m", "playwright", "install", "chromium"], check=True
    )

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await (await browser.new_context(ignore_https_errors=True)).new_page()
        await page.goto(auth_url, wait_until="networkidle", timeout=30000)

        # Login
        await submit_username_password(page, username, password)

        # Wait for credential validation (up to 30s)
        for i in range(30):
            await asyncio.sleep(1)
            text = await page.inner_text("body")
            if "Login failed" in text:
                print("[-] Login failed")
                return None
            if "TAU Google Authenticator Enrollment" in text:
                print("[i] Enrollment/IdP chooser page reached")
                for link in await page.query_selector_all("a"):
                    href = await link.get_attribute("href")
                    if href:
                        print(f"[i] link: {href}")
                for form in await page.query_selector_all("form"):
                    action = await form.get_attribute("action")
                    print(f"[i] form action: {action}")
                auth_link = await page.query_selector('a[href*="id=TAUGoogleAuthenticator"]')
                if auth_link is not None:
                    href = await auth_link.get_attribute("href")
                    if href:
                        print(f"[i] navigating to TAUGoogleAuthenticator: {href}")
                        await page.goto(href, wait_until="networkidle", timeout=30000)
                        await asyncio.sleep(1)
                        await submit_username_password(page, username, password)
                        await asyncio.sleep(2)
                        continue
                await page.screenshot(path="/tmp/vpn-enrollment-page.png")
                await asyncio.sleep(2)
                break
            if not await page.query_selector_all('input[type="password"]:visible'):
                break
            if "globalprotectcallback" in text:
                break
            if (i + 1) % 5 == 0:
                print(f"[i] waiting for post-login page transition... {i + 1}s")

        # Fill OTP
        otp_filled = False
        for inp in await page.query_selector_all("input:visible"):
            inp_type = await inp.get_attribute("type")
            name = await inp.get_attribute("name") or ""
            if name == "Ecom_User_ID" or inp_type == "password":
                continue
            if inp_type in ("text", "tel", "number"):
                await inp.fill(otp)
                if btn := await page.query_selector(SUBMIT_SEL):
                    await btn.click()
                else:
                    await inp.press("Enter")
                otp_filled = True
                break

        if not otp_filled:
            print("[-] No visible OTP field found after login")
            await page.screenshot(path="/tmp/vpn-no-otp-field.png")
            return None

        print("[i] OTP submitted; waiting for GlobalProtect callback")
        for i in range(90):
            await asyncio.sleep(1)
            body = await page.inner_text("body")
            if "Login failed" in body:
                print("[-] Login failed")
                return None
            if "globalprotectcallback" in body:
                break
            if (i + 1) % 5 == 0:
                print(f"[i] waiting for GlobalProtect callback... {i + 1}s")

        # Extract callback URL from link or page source
        for link in await page.query_selector_all("a"):
            href = await link.get_attribute("href")
            if href and "globalprotectcallback" in href:
                await browser.close()
                return href

        if m := re.search(r'globalprotectcallback:[^\s"<>\']+', await page.content()):
            await browser.close()
            return m.group(0)

        await page.screenshot(path="/tmp/vpn-auth-failed.png")
        print("[-] No callback found after waiting for GlobalProtect callback (screenshot: /tmp/vpn-auth-failed.png)")
        await browser.close()
        return None


def extract_cookie(callback_url: str) -> tuple[str, str | None] | tuple[None, None]:
    for prefix in ("globalprotectcallback://", "globalprotectcallback:"):
        if callback_url.startswith(prefix):
            data = callback_url[len(prefix) :]
            break
    else:
        return None, None

    try:
        decoded = base64.b64decode(data + "=" * (-len(data) % 4)).decode()
    except Exception:
        return None, None

    cookie = re.search(r"<prelogin-cookie>([^<]+)</prelogin-cookie>", decoded)
    user = re.search(r"<saml-username>([^<]+)</saml-username>", decoded)
    return (
        (cookie.group(1), user.group(1) if user else None) if cookie else (None, None)
    )


def tun0_up() -> bool:
    return (
        subprocess.run(
            ["ip", "addr", "show", "tun0"],
            capture_output=True,
        ).returncode
        == 0
    )


def build_split_tunnel_script() -> str | None:
    if not os.path.isfile(TAU_SPLIT_SCRIPT):
        return None
    if not os.access(TAU_SPLIT_SCRIPT, os.X_OK):
        print(f"[-] Split script exists but is not executable: {TAU_SPLIT_SCRIPT}")
        return None

    return TAU_SPLIT_SCRIPT


def connect_vpn(cookie: str, username: str) -> bool:
    cmd = [
        "sudo",
        "openconnect",
        "--protocol=gp",
        f"--user={username}",
        "--usergroup=gateway:prelogin-cookie",
        "--passwd-on-stdin",
        "--background",
    ]
    split_script = build_split_tunnel_script()
    if split_script:
        cmd.extend(["--script", split_script])
    else:
        print("[-] split-tunnel script unavailable; falling back to full tunnel")
    cmd.append("vpn.tau.ac.il")

    try:
        subprocess.run(
            cmd,
            input=cookie + "\n",
            capture_output=True,
            text=True,
            timeout=30,
        )
    except subprocess.TimeoutExpired:
        pass
    return tun0_up()


async def main():
    username = os.environ.get("TAU_USERNAME")
    password = os.environ.get("TAU_PASSWORD")
    args = sys.argv[1:]

    if len(args) >= 3:
        username, password, otp = args[0], args[1], args[2]
    elif len(args) >= 1:
        otp = args[0]
    else:
        otp = input("Enter 2FA code: ").strip()

    if not username or not password:
        sys.exit("Error: set TAU_USERNAME/TAU_PASSWORD env vars, or pass as arguments")

    proc, auth_url = start_gpclient(username)
    if not auth_url:
        proc.terminate()
        sys.exit("[-] Failed to get auth URL from gpclient")

    callback_url = await complete_saml_auth(auth_url, username, password, otp)
    proc.terminate()
    if not callback_url:
        sys.exit("[-] SAML auth failed (OTP expired?)")

    cookie, saml_user = extract_cookie(callback_url)
    if not cookie:
        sys.exit("[-] Failed to extract cookie")

    if connect_vpn(cookie, saml_user or username):
        print("[+] VPN connected. Disconnect: sudo pkill openconnect")
    else:
        sys.exit("[-] VPN connection failed (no tun0)")


if __name__ == "__main__":
    asyncio.run(main())
