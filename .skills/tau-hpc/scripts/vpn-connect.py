#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#   "playwright==1.58.0",
# ]
# ///
"""TAU GlobalProtect VPN connector with session-cookie reuse.

Usage:
  uv run vpn-connect.py --status
  uv run vpn-connect.py --reuse
  uv run vpn-connect.py [USERNAME PASSWORD] OTP
  uv run vpn-connect.py --refresh-auth [USERNAME PASSWORD] OTP

Credentials default to TAU_USERNAME / TAU_PASSWORD. Authentication cookies are
stored only in the current user's runtime directory, with mode 0600, and expire
from the local cache after 12 hours.
"""

import argparse
import asyncio
import base64
import contextlib
import fcntl
import html
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass

SUBMIT_SEL = (
    'input[type="submit"], button[type="submit"],'
    ' input[value="Sign in"], button:has-text("Validate"), input[value="Validate Code"]'
)
VPN_HOST = "vpn.tau.ac.il"
TAU_ROUTE_IPS = ("132.66.242.133", "132.67.132.36")
CACHE_MAX_AGE_SECONDS = 12 * 60 * 60

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TAU_SPLIT_SCRIPT = os.path.join(SCRIPT_DIR, "tau-vpnc-split.sh")


@dataclass(frozen=True)
class SamlCredential:
    username: str
    prelogin_cookie: str | None
    portal_userauthcookie: str | None
    created_at: float


def runtime_dir() -> Path:
    configured = os.environ.get("XDG_RUNTIME_DIR")
    default = Path(f"/run/user/{os.getuid()}")
    base = Path(configured) if configured else default
    if not base.is_dir():
        base = Path.home() / ".cache"

    return base / "tau-vpn"


def ensure_runtime_dir() -> Path:
    path = runtime_dir()
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    path.chmod(0o700)
    return path


def auth_cache_path() -> Path:
    return runtime_dir() / "saml-auth.json"


def pid_file_path() -> Path:
    return runtime_dir() / "openconnect.pid"


def save_credential(credential: SamlCredential) -> None:
    target = auth_cache_path()
    ensure_runtime_dir()
    fd, temporary_name = tempfile.mkstemp(prefix=".saml-auth.", dir=target.parent)
    temporary = Path(temporary_name)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(asdict(credential), stream)
            stream.write("\n")
        temporary.replace(target)
        target.chmod(0o600)
    finally:
        with contextlib.suppress(FileNotFoundError):
            temporary.unlink()


def load_credential() -> SamlCredential | None:
    path = auth_cache_path()
    try:
        metadata = path.lstat()
    except FileNotFoundError:
        return None

    if (
        not stat.S_ISREG(metadata.st_mode)
        or metadata.st_uid != os.getuid()
        or metadata.st_mode & 0o077
    ):
        print(f"[-] Ignoring insecure VPN authentication cache: {path}")
        return None

    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
        credential = SamlCredential(**payload)
    except (OSError, TypeError, ValueError, json.JSONDecodeError):
        print(f"[-] Ignoring invalid VPN authentication cache: {path}")
        return None

    if time.time() - credential.created_at > CACHE_MAX_AGE_SECONDS:
        print(
            "[i] Cached VPN authentication is older than 12 hours; fresh MFA required"
        )
        return None
    if not credential.username or not (
        credential.prelogin_cookie or credential.portal_userauthcookie
    ):
        return None
    return credential


@contextlib.contextmanager
def connection_lock():
    path = ensure_runtime_dir() / "connect.lock"
    with path.open("w", encoding="utf-8") as stream:
        try:
            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit(
                "[-] Another TAU VPN connection attempt is already running"
            )
        yield


async def submit_username_password(page, username: str, password: str) -> bool:
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

    filled = False
    for selector in username_fields:
        if await page.query_selector(selector):
            await page.fill(selector, username)
            filled = True
            break
    for selector in password_fields:
        if await page.query_selector(selector):
            await page.fill(selector, password)
            filled = True
            break

    if not filled:
        return False
    if btn := await page.query_selector(SUBMIT_SEL):
        await btn.click()
    else:
        await page.keyboard.press("Enter")
    return True


def start_gpclient(username: str) -> tuple[subprocess.Popen, str | None]:
    proc = subprocess.Popen(
        [
            "sudo",
            "gpclient",
            "connect",
            VPN_HOST,
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
        start_new_session=True,
    )
    assert proc.stdout is not None
    for _ in range(30):
        line = proc.stdout.readline()
        if not line:
            break
        if match := re.search(r"(http://[0-9.]+:[0-9]+/[a-f0-9-]+)", line):
            return proc, match.group(1)
    return proc, None


def stop_gpclient(proc: subprocess.Popen) -> None:
    with contextlib.suppress(ProcessLookupError):
        os.killpg(proc.pid, signal.SIGTERM)
    with contextlib.suppress(subprocess.TimeoutExpired):
        proc.wait(timeout=5)
    if proc.poll() is None:
        with contextlib.suppress(ProcessLookupError):
            os.killpg(proc.pid, signal.SIGKILL)


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

    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=True)
        page = await (await browser.new_context(ignore_https_errors=True)).new_page()
        await page.goto(auth_url, wait_until="networkidle", timeout=30000)

        await submit_username_password(page, username, password)

        for i in range(30):
            await asyncio.sleep(1)
            text = await page.inner_text("body")
            if "Login failed" in text:
                print("[-] Login failed")
                return None
            if "TAU Google Authenticator Enrollment" in text:
                print("[i] Enrollment/IdP chooser page reached")
                auth_link = await page.query_selector(
                    'a[href*="id=TAUGoogleAuthenticator"]'
                )
                if auth_link is not None:
                    href = await auth_link.get_attribute("href")
                    if href:
                        await page.goto(href, wait_until="networkidle", timeout=30000)
                        await asyncio.sleep(1)
                        await submit_username_password(page, username, password)
                        await asyncio.sleep(2)
                        continue
                break
            if not await page.query_selector_all('input[type="password"]:visible'):
                break
            if "globalprotectcallback" in text:
                break
            if (i + 1) % 5 == 0:
                print(f"[i] waiting for post-login page transition... {i + 1}s")

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

        for link in await page.query_selector_all("a"):
            href = await link.get_attribute("href")
            if href and "globalprotectcallback" in href:
                await browser.close()
                return href

        if match := re.search(
            r'globalprotectcallback:[^\s"<>\']+', await page.content()
        ):
            await browser.close()
            return match.group(0)

        print("[-] No callback found after waiting for GlobalProtect callback")
        await browser.close()
        return None


def extract_credential(callback_url: str) -> SamlCredential | None:
    for prefix in ("globalprotectcallback://", "globalprotectcallback:"):
        if callback_url.startswith(prefix):
            data = callback_url[len(prefix) :]
            break
    else:
        return None

    try:
        decoded = base64.b64decode(data + "=" * (-len(data) % 4)).decode()
    except (UnicodeDecodeError, ValueError):
        return None

    def tag(name: str) -> str | None:
        match = re.search(rf"<{name}>([^<]+)</{name}>", decoded)
        return html.unescape(match.group(1)) if match else None

    username = tag("saml-username")
    prelogin_cookie = tag("prelogin-cookie")
    portal_userauthcookie = tag("portal-userauthcookie")
    if not username or not (prelogin_cookie or portal_userauthcookie):
        return None
    return SamlCredential(
        username=username,
        prelogin_cookie=prelogin_cookie,
        portal_userauthcookie=portal_userauthcookie,
        created_at=time.time(),
    )


def tun0_up() -> bool:
    return (
        subprocess.run(
            ["ip", "addr", "show", "tun0"],
            capture_output=True,
        ).returncode
        == 0
    )


def split_routes_up() -> bool:
    for address in TAU_ROUTE_IPS:
        result = subprocess.run(
            ["ip", "route", "get", address],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0 or " dev tun0 " not in f" {result.stdout} ":
            return False
    return True


def openconnect_running() -> bool:
    path = pid_file_path()
    with contextlib.suppress(OSError, ValueError):
        pid = int(path.read_text(encoding="utf-8").strip())
        os.kill(pid, 0)
        return True
    return (
        subprocess.run(["pgrep", "-x", "openconnect"], capture_output=True).returncode
        == 0
    )


def print_status() -> int:
    tunnel = tun0_up()
    routes = tunnel and split_routes_up()
    process = openconnect_running()
    cache = load_credential()
    if tunnel and routes:
        print(
            "[+] TAU VPN connected: tun0 and both split routes are active; "
            f"cached_reauth={'yes' if cache else 'no'}"
        )
        return 0
    if process:
        print(
            "[i] openconnect is running but tun0/routes are not ready; reconnect may be in progress"
        )
        return 1
    print(f"[-] TAU VPN disconnected; cached_reauth={'yes' if cache else 'no'}")
    return 1


def build_split_tunnel_script() -> str | None:
    if not os.path.isfile(TAU_SPLIT_SCRIPT):
        return None
    if not os.access(TAU_SPLIT_SCRIPT, os.X_OK):
        print(f"[-] Split script exists but is not executable: {TAU_SPLIT_SCRIPT}")
        return None
    return TAU_SPLIT_SCRIPT


def connect_with_secret(username: str, secret: str, usergroup: str) -> bool:
    cmd = [
        "sudo",
        "openconnect",
        "--protocol=gp",
        f"--user={username}",
        f"--usergroup={usergroup}",
        "--passwd-on-stdin",
        "--background",
        "--reconnect-timeout=3600",
        "--force-dpd=30",
        f"--pid-file={pid_file_path()}",
        "--syslog",
    ]
    split_script = build_split_tunnel_script()
    if split_script:
        cmd.extend(["--script", split_script])
    else:
        print("[-] split-tunnel script unavailable; refusing full-tunnel fallback")
        return False
    cmd.append(VPN_HOST)

    try:
        result = subprocess.run(
            cmd,
            input=secret + "\n",
            capture_output=True,
            text=True,
            timeout=45,
        )
    except subprocess.TimeoutExpired:
        result = None

    for _ in range(15):
        if tun0_up() and split_routes_up():
            return True
        time.sleep(1)

    if result is not None and result.returncode != 0:
        print(
            f"[i] Cached VPN authentication was rejected (openconnect exit {result.returncode})"
        )
    return False


def connect_vpn(credential: SamlCredential, *, fresh: bool) -> bool:
    methods: list[tuple[str, str]] = []
    if fresh and credential.prelogin_cookie:
        methods.append(("gateway:prelogin-cookie", credential.prelogin_cookie))
    if credential.portal_userauthcookie:
        methods.append(
            ("portal:portal-userauthcookie", credential.portal_userauthcookie)
        )
    if not fresh and credential.prelogin_cookie:
        methods.append(("gateway:prelogin-cookie", credential.prelogin_cookie))

    for usergroup, secret in methods:
        print(f"[i] Trying VPN authentication reuse via {usergroup}")
        if connect_with_secret(credential.username, secret, usergroup):
            return True
        if openconnect_running():
            print("[i] openconnect is still retrying; not starting another tunnel")
            return False
    return False


def parse_credentials(values: list[str]) -> tuple[str | None, str | None, str | None]:
    username = os.environ.get("TAU_USERNAME")
    password = os.environ.get("TAU_PASSWORD")
    otp = None
    if len(values) == 3:
        username, password, otp = values
    elif len(values) == 1:
        otp = values[0]
    elif values:
        raise SystemExit("Usage: vpn-connect.py [USERNAME PASSWORD] OTP")
    return username, password, otp


async def authenticate(username: str, password: str, otp: str) -> SamlCredential:
    proc, auth_url = start_gpclient(username)
    if not auth_url:
        stop_gpclient(proc)
        raise SystemExit("[-] Failed to get auth URL from gpclient")

    try:
        callback_url = await complete_saml_auth(auth_url, username, password, otp)
    finally:
        stop_gpclient(proc)
    if not callback_url:
        raise SystemExit("[-] SAML auth failed (OTP expired?)")

    credential = extract_credential(callback_url)
    if not credential:
        raise SystemExit("[-] Failed to extract GlobalProtect authentication cookies")
    save_credential(credential)
    return credential


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--status", action="store_true", help="show tunnel and cached-auth state"
    )
    parser.add_argument(
        "--reuse",
        action="store_true",
        help="use cached authentication only; never prompt for MFA",
    )
    parser.add_argument(
        "--refresh-auth",
        action="store_true",
        help="obtain and cache fresh authentication without replacing an active tunnel",
    )
    parser.add_argument("values", nargs="*", metavar="VALUE")
    args = parser.parse_args()

    if args.status:
        raise SystemExit(print_status())

    username, password, otp = parse_credentials(args.values)
    with connection_lock():
        connected = tun0_up() and split_routes_up()
        if connected and not args.refresh_auth:
            print(
                "[+] Existing shared TAU VPN tunnel is healthy; no authentication needed"
            )
            return
        if openconnect_running() and not connected and not args.refresh_auth:
            raise SystemExit(
                "[i] openconnect is already retrying; not starting a duplicate tunnel"
            )

        cached = load_credential()
        if not args.refresh_auth and cached:
            if connect_vpn(cached, fresh=False):
                print(
                    "[+] VPN reconnected with cached authentication; no new MFA code used"
                )
                return
            if args.reuse:
                raise SystemExit(
                    "[-] Cached VPN authentication failed; fresh MFA required"
                )
        elif args.reuse:
            raise SystemExit(
                "[-] No reusable VPN authentication is cached; fresh MFA required"
            )

        if otp is None:
            otp = input("Enter 2FA code: ").strip()
        if not re.fullmatch(r"[0-9]{6}", otp):
            raise SystemExit("[-] TAU MFA code must contain exactly six digits")
        if not username or not password:
            raise SystemExit(
                "Error: set TAU_USERNAME/TAU_PASSWORD env vars, or pass them as arguments"
            )

        credential = await authenticate(username, password, otp)
        if args.refresh_auth:
            print(
                "[+] Cached fresh VPN authentication without changing the active tunnel; "
                "use --reuse after the next disconnect"
            )
            return

        if connect_vpn(credential, fresh=True):
            print(
                "[+] VPN connected; future reconnects will try cached authentication first"
            )
        else:
            raise SystemExit(
                "[-] VPN connection failed (tun0/split routes unavailable)"
            )


if __name__ == "__main__":
    asyncio.run(main())
