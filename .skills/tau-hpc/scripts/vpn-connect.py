#!/usr/bin/env python3
"""Connect to TAU GlobalProtect VPN (pure-HTTP SAML auth + 12h cookie cache).

Examples:
  vpn-connect.py --status              Check tunnel, split routes, and cache
  vpn-connect.py --reuse               Reconnect from 12h cache (never prompts)
  vpn-connect.py 123456                Connect using a 6-digit MFA code
  vpn-connect.py --refresh-auth 123456 Refresh cached cookie without touching tun0

Credentials: TAU_USERNAME / TAU_PASSWORD env vars, falling back to ~/.config/tau-hpc/env.
Exit status: 0 if connected/refreshed, nonzero otherwise.
"""

from __future__ import annotations

import argparse
import base64
import contextlib
import fcntl
import html
from html.parser import HTMLParser
import http.cookiejar
import json
import os
from pathlib import Path
import re
import shlex
import socket
import ssl
import stat
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

VPN_HOST = "vpn.tau.ac.il"
PRELOGIN_URL = f"https://{VPN_HOST}/ssl-vpn/prelogin.esp"
TAU_ROUTE_IPS = ("132.66.242.133", "132.67.132.36")
CACHE_TTL = 12 * 3600
VPNC_SCRIPTS = ("/usr/share/vpnc-scripts/vpnc-script", "/etc/vpnc/vpnc-script")


def state_dir() -> Path:
    base = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")
    return (base if base.is_dir() else Path.home() / ".cache") / "tau-vpn"


def get_creds() -> tuple[str | None, str | None]:
    user, pw = os.environ.get("TAU_USERNAME"), os.environ.get("TAU_PASSWORD")
    if not pw and (home := os.environ.get("HOME")):
        env_file = Path(home) / ".config/tau-hpc/env"
        if env_file.is_file():
            for line in env_file.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    k, val = k.removeprefix("export ").strip(), (shlex.split(v)[0] if v.strip() else "")
                    if k == "TAU_USERNAME" and not user:
                        user = val
                    elif k == "TAU_PASSWORD" and not pw:
                        pw = val
    return user, pw


def load_cache() -> dict | None:
    path = state_dir() / "saml-auth.json"
    try:
        st = path.lstat()
        if not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid() or st.st_mode & 0o077:
            return None
        d = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None
    if time.time() - d.get("created_at", 0) > CACHE_TTL:
        print("[i] Cached VPN auth expired (>12h); fresh MFA required")
        return None
    return d if d.get("username") and (d.get("prelogin_cookie") or d.get("portal_userauthcookie")) else None


def save_cache(cred: dict) -> None:
    d = state_dir()
    d.mkdir(mode=0o700, parents=True, exist_ok=True)
    d.chmod(0o700)
    fd, tmp_name = tempfile.mkstemp(prefix=".saml-auth.", dir=d)
    tmp = Path(tmp_name)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(cred, f)
            f.write("\n")
        tmp.replace(d / "saml-auth.json")
        (d / "saml-auth.json").chmod(0o600)
    finally:
        tmp.unlink(missing_ok=True)


class _FormParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.forms: list[dict] = []
        self._cur: dict | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k.lower(): (v or "") for k, v in attrs}
        if tag.lower() == "form":
            self._cur = {"action": a.get("action", ""), "method": (a.get("method") or "GET").upper(), "inputs": []}
            self.forms.append(self._cur)
        elif tag.lower() == "input" and self._cur is not None:
            self._cur["inputs"].append({"type": (a.get("type") or "text").lower(), "name": a.get("name", ""), "value": a.get("value", "")})

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() == "form":
            self._cur = None


def parse_forms(body: str) -> list[dict]:
    p = _FormParser()
    p.feed(body)
    return p.forms


def extract_cred(headers: dict[str, str], body: str, fallback_user: str) -> dict | None:
    h = {k.lower(): v.strip() for k, v in headers.items() if v}
    if h.get("prelogin-cookie") or h.get("portal-userauthcookie"):
        return {
            "username": h.get("saml-username") or fallback_user,
            "prelogin_cookie": h.get("prelogin-cookie") or None,
            "portal_userauthcookie": h.get("portal-userauthcookie") or None,
            "created_at": time.time(),
        }
    if m := re.search(r'globalprotectcallback:(?://)?([^\s"<>\']+)', body):
        raw = html.unescape(m.group(1))
        with contextlib.suppress(UnicodeDecodeError, ValueError):
            xml = base64.b64decode(raw + "=" * (-len(raw) % 4)).decode()
            tag = lambda n: html.unescape(x.group(1)) if (x := re.search(rf"<{n}>([^<]+)</{n}>", xml)) else None
            u, p, po = tag("saml-username"), tag("prelogin-cookie"), tag("portal-userauthcookie")
            if u and (p or po):
                return {"username": u, "prelogin_cookie": p, "portal_userauthcookie": po, "created_at": time.time()}
    return None


def saml_auth(username: str, password: str, otp: str) -> dict:
    ctx = ssl.create_default_context()
    ctx.options |= getattr(ssl, "OP_LEGACY_SERVER_CONNECT", 0x4)
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()), urllib.request.HTTPSHandler(context=ctx))
    opener.addheaders = [("User-Agent", "Mozilla/5.0")]

    def fetch(url: str, data: dict[str, str] | bytes | None = None, hdrs: dict[str, str] | None = None) -> tuple[str, dict[str, str], str]:
        payload = urllib.parse.urlencode(data).encode() if isinstance(data, dict) else data
        with opener.open(urllib.request.Request(url, data=payload, headers=hdrs or {}), timeout=25) as r:
            return r.geturl(), dict(r.headers.items()), r.read().decode("utf-8", "replace")

    def submit(base: str, form: dict, extra: dict[str, str] | None = None) -> tuple[str, dict[str, str], str]:
        fields = {i["name"]: i["value"] for i in form["inputs"] if i["name"]} | (extra or {})
        action = urllib.parse.urljoin(base, html.unescape(form["action"]))
        if form["method"] == "POST":
            return fetch(action, fields)
        qs = urllib.parse.urlencode(fields)
        return fetch(f"{action}{'&' if '?' in action else '?'}{qs}" if qs else action)

    def follow(url: str, hdrs: dict[str, str], body: str) -> tuple[str, dict[str, str], str, dict | None]:
        for _ in range(6):
            if cred := extract_cred(hdrs, body, username):
                return url, hdrs, body, cred
            forms = parse_forms(body)
            if len(forms) == 1 and not [i for i in forms[0]["inputs"] if i["type"] not in {"hidden", "submit", "button", "image"}]:
                if "submit()" in body or any(i["name"] in {"SAMLRequest", "SAMLResponse"} for i in forms[0]["inputs"]):
                    url, hdrs, body = submit(url, forms[0])
                    continue
            break
        return url, hdrs, body, extract_cred(hdrs, body, username)

    # 1. Prelogin -> SAMLRequest POST to nidp
    _, _, xml_text = fetch(PRELOGIN_URL, b"tmp=tmp&clientVer=4100&clientos=Linux", {"User-Agent": "PAN GlobalProtect"})
    saml_b64 = (ET.fromstring(xml_text).findtext("saml-request") or "").strip()
    if not saml_b64:
        raise SystemExit("[-] GlobalProtect prelogin returned no saml-request")
    url, hdrs, body = submit(PRELOGIN_URL, parse_forms(base64.b64decode(saml_b64).decode("utf-8", "replace"))[0])
    url, hdrs, body, cred = follow(url, hdrs, body)
    if cred:
        return cred

    # 2. IdP chooser -> TAUGoogleAuthenticator
    if m := re.search(r'href="([^"]*id=TAUGoogleAuthenticator[^"]*)"', body, re.I):
        url, hdrs, body = fetch(urllib.parse.urljoin(url, html.unescape(m.group(1))))
        url, hdrs, body, cred = follow(url, hdrs, body)
        if cred:
            return cred

    # 3. Username + password
    login_form = next((f for f in parse_forms(body) if any(i["type"] == "password" for i in f["inputs"])), None)
    if not login_form:
        raise SystemExit(f"[-] Expected login form at {url}")
    u_field = next(i["name"] for i in login_form["inputs"] if i["name"] == "Ecom_User_ID" or (i["type"] == "text" and i["name"]))
    p_field = next(i["name"] for i in login_form["inputs"] if i["type"] == "password" and i["name"])
    url, hdrs, body = submit(url, login_form, {u_field: username, p_field: password})
    if "Login failed" in body:
        raise SystemExit("[-] TAU IdP rejected username/password")
    url, hdrs, body, cred = follow(url, hdrs, body)
    if cred:
        return cred

    # 4. OTP (gtoken) -> SAMLResponse POST back to GlobalProtect ACS
    otp_pair = next(((f, i["name"]) for f in parse_forms(body) for i in f["inputs"] if i["name"] == "gtoken" or (i["type"] in {"text", "tel", "number"} and i["name"] not in {"", "Ecom_User_ID"})), None)
    if not otp_pair:
        raise SystemExit(f"[-] Expected OTP form at {url}")
    url, hdrs, body = submit(url, otp_pair[0], {otp_pair[1]: otp})
    if "Login failed" in body or ("Invalid" in body and "SAMLResponse" not in body):
        raise SystemExit("[-] TAU IdP rejected OTP (expired or incorrect?)")
    url, hdrs, body, cred = follow(url, hdrs, body)
    if not cred:
        raise SystemExit(f"[-] No GlobalProtect auth cookie found after SAML flow (ended at {url})")
    return cred


def tunnel_healthy() -> bool:
    if subprocess.run(["ip", "addr", "show", "tun0"], capture_output=True).returncode != 0:
        return False
    return all(
        (r := subprocess.run(["ip", "route", "get", ip], capture_output=True, text=True)).returncode == 0
        and " dev tun0 " in f" {r.stdout} "
        for ip in TAU_ROUTE_IPS
    )


def openconnect_running() -> bool:
    with contextlib.suppress(OSError, ValueError):
        os.kill(int((state_dir() / "openconnect.pid").read_text().strip()), 0)
        return True
    return subprocess.run(["pgrep", "-x", "openconnect"], capture_output=True).returncode == 0


def split_tunnel_cmd() -> str:
    vpnc = next((p for p in VPNC_SCRIPTS if os.path.isfile(p) and os.access(p, os.X_OK)), None)
    if not vpnc:
        raise SystemExit(f"[-] vpnc-script not found in {', '.join(VPNC_SCRIPTS)}")
    routes = [("132.66.0.0", "255.255.0.0", "16"), ("132.67.0.0", "255.255.0.0", "16")]
    for host in os.environ.get("TAU_EXTRA_VPN_HOSTS", "").split():
        with contextlib.suppress(socket.gaierror):
            for ip in sorted({info[4][0] for info in socket.getaddrinfo(host, None, socket.AF_INET)}):
                routes.append((ip, "255.255.255.255", "32"))
    env = [f"CISCO_SPLIT_INC={len(routes)}"]
    for i, (addr, mask, masklen) in enumerate(routes):
        env.append(f"CISCO_SPLIT_INC_{i}_ADDR={addr} CISCO_SPLIT_INC_{i}_MASK={mask} CISCO_SPLIT_INC_{i}_MASKLEN={masklen}")
    return f"{' '.join(env)} exec {shlex.quote(vpnc)}"


def connect_vpn(cred: dict, *, fresh: bool) -> bool:
    script_cmd = split_tunnel_cmd()
    order = (("gateway:prelogin-cookie", "prelogin_cookie"), ("portal:portal-userauthcookie", "portal_userauthcookie"))
    methods = [(g, cred[k]) for g, k in (order if fresh else reversed(order)) if cred.get(k)]
    for group, secret in methods:
        cmd = [
            "sudo", "openconnect", "--protocol=gp", f"--user={cred['username']}",
            f"--usergroup={group}", "--passwd-on-stdin", "--background",
            "--reconnect-timeout=3600", "--force-dpd=30",
            f"--pid-file={state_dir() / 'openconnect.pid'}", "--syslog",
            "--script", script_cmd, VPN_HOST,
        ]
        with contextlib.suppress(subprocess.TimeoutExpired):
            res = subprocess.run(cmd, input=secret + "\n", capture_output=True, text=True, timeout=45)
            if res.returncode != 0:
                print(f"[i] openconnect rejected {group} (exit {res.returncode})")
        for _ in range(15):
            if tunnel_healthy():
                return True
            time.sleep(1)
        if openconnect_running():
            print("[i] openconnect is still retrying; not starting another tunnel")
            return False
    return False


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--status", action="store_true", help="print VPN and cached-auth status (exit 0 if healthy)")
    p.add_argument("--reuse", action="store_true", help="reconnect using cached cookie only; never prompt for OTP")
    p.add_argument("--refresh-auth", action="store_true", help="authenticate and update cached cookie without replacing tun0")
    p.add_argument("otp", nargs="?", help="6-digit TAU Google Authenticator code")
    args = p.parse_args()

    if args.status:
        c = "yes" if load_cache() else "no"
        if tunnel_healthy():
            print(f"[+] TAU VPN connected: tun0 and both split routes are active; cached_reauth={c}")
            raise SystemExit(0)
        print("[i] openconnect running; waiting on tun0/routes" if openconnect_running() else f"[-] TAU VPN disconnected; cached_reauth={c}")
        raise SystemExit(1)

    d = state_dir()
    d.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (d / "connect.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise SystemExit("[-] Another TAU VPN connection attempt is already running")

        if tunnel_healthy() and not args.refresh_auth:
            print("[+] Existing shared TAU VPN tunnel is healthy; no authentication needed")
            return
        if openconnect_running() and not tunnel_healthy() and not args.refresh_auth:
            raise SystemExit("[i] openconnect is already retrying; not starting a duplicate tunnel")

        if not args.refresh_auth and (cached := load_cache()):
            if connect_vpn(cached, fresh=False):
                print("[+] VPN reconnected with cached authentication")
                return
            if args.reuse:
                raise SystemExit("[-] Cached VPN authentication failed; fresh MFA required")
        elif args.reuse:
            raise SystemExit("[-] No reusable VPN authentication cached; fresh MFA required")

        otp = args.otp if args.otp is not None else input("Enter 2FA code: ").strip()
        if not re.fullmatch(r"[0-9]{6}", otp):
            raise SystemExit("[-] TAU MFA code must contain exactly six digits")
        user, pw = get_creds()
        if not user or not pw:
            raise SystemExit("[-] Set TAU_USERNAME/TAU_PASSWORD (or ~/.config/tau-hpc/env)")

        try:
            cred = saml_auth(user, pw, otp)
        except (urllib.error.URLError, TimeoutError, ET.ParseError) as exc:
            raise SystemExit(f"[-] SAML HTTP auth error: {exc}") from exc
        save_cache(cred)
        if args.refresh_auth:
            print("[+] Cached fresh VPN authentication without changing the active tunnel")
            return
        if not connect_vpn(cred, fresh=True):
            raise SystemExit("[-] VPN connection failed (tun0/split routes unavailable)")
        print("[+] VPN connected")


if __name__ == "__main__":
    main()
