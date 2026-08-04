import asyncio
import base64
import importlib.util
import os
from pathlib import Path
import stat
import sys
import tempfile
import time
import unittest
from unittest import mock


SCRIPT = Path(__file__).with_name("vpn-connect.py")
SPEC = importlib.util.spec_from_file_location("tau_vpn_connect", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
vpn = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = vpn
SPEC.loader.exec_module(vpn)


class VpnConnectTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.runtime_patch = mock.patch.dict(
            os.environ, {"XDG_RUNTIME_DIR": self.temporary.name}
        )
        self.runtime_patch.start()
        self.addCleanup(self.runtime_patch.stop)

    def credential(self, **overrides) -> vpn.SamlCredential:
        values = {
            "username": "researcher",
            "prelogin_cookie": "prelogin-secret",
            "portal_userauthcookie": "portal-secret",
            "created_at": time.time(),
        }
        values.update(overrides)
        return vpn.SamlCredential(**values)

    def test_extracts_both_globalprotect_cookies(self) -> None:
        xml = (
            "<saml-auth-status>1</saml-auth-status>"
            "<saml-username>researcher</saml-username>"
            "<prelogin-cookie>prelogin-secret</prelogin-cookie>"
            "<portal-userauthcookie>portal-secret</portal-userauthcookie>"
        )
        callback = "globalprotectcallback:" + base64.b64encode(xml.encode()).decode()

        credential = vpn.extract_credential(callback)

        self.assertIsNotNone(credential)
        assert credential is not None
        self.assertEqual(credential.username, "researcher")
        self.assertEqual(credential.prelogin_cookie, "prelogin-secret")
        self.assertEqual(credential.portal_userauthcookie, "portal-secret")

    def test_cache_is_private_and_round_trips(self) -> None:
        credential = self.credential()

        vpn.save_credential(credential)

        cache = vpn.auth_cache_path()
        self.assertEqual(stat.S_IMODE(cache.stat().st_mode), 0o600)
        self.assertEqual(vpn.load_credential(), credential)

    def test_expired_cache_is_not_reused(self) -> None:
        vpn.save_credential(
            self.credential(created_at=time.time() - vpn.CACHE_MAX_AGE_SECONDS - 1)
        )

        self.assertIsNone(vpn.load_credential())
        self.assertTrue(vpn.auth_cache_path().exists())

    def test_status_does_not_create_runtime_directory(self) -> None:
        with (
            mock.patch.object(vpn, "tun0_up", return_value=False),
            mock.patch.object(vpn, "openconnect_running", return_value=False),
        ):
            self.assertEqual(vpn.print_status(), 1)

        self.assertFalse(vpn.runtime_dir().exists())

    def test_reuse_prefers_portal_authentication_cookie(self) -> None:
        with mock.patch.object(
            vpn, "connect_with_secret", return_value=True
        ) as connect:
            connected = vpn.connect_vpn(self.credential(), fresh=False)

        self.assertTrue(connected)
        connect.assert_called_once_with(
            "researcher", "portal-secret", "portal:portal-userauthcookie"
        )

    def test_healthy_shared_tunnel_never_authenticates(self) -> None:
        authenticate = mock.AsyncMock()
        with (
            mock.patch.object(sys, "argv", [str(SCRIPT), "--reuse"]),
            mock.patch.object(vpn, "tun0_up", return_value=True),
            mock.patch.object(vpn, "split_routes_up", return_value=True),
            mock.patch.object(vpn, "authenticate", authenticate),
        ):
            asyncio.run(vpn.main())

        authenticate.assert_not_awaited()


if __name__ == "__main__":
    unittest.main()
