import os
from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch


REMOTE = runpy.run_path(str(Path(__file__).with_name("remote")), run_name="tau_remote")


class RemoteTest(unittest.TestCase):
    def test_power_is_the_default_target(self):
        args = REMOTE["parse_args"](["-C", "project", "hostname"])

        self.assertEqual(args.target, "power")
        self.assertEqual(args.directory, "project")
        self.assertEqual(args.command, ["hostname"])

    def test_power_direct_command_quotes_arguments_and_sets_environment(self):
        args = REMOTE["parse_args"](
            ["power", "-C", "project with spaces", "printf", "%s\\n", "a b"]
        )
        command = REMOTE["build_remote_command"](args)

        self.assertIn("export HOME=/scratch300/galaharoni", command)
        self.assertIn("/scratch300/galaharoni/project with spaces", command)
        self.assertIn("exec printf", command)
        self.assertIn("a b", command)

    def test_shell_command_is_preserved(self):
        args = REMOTE["parse_args"](
            ["power", "-C", "project", "-c", "squeue -j 42; tail -3 job.log"]
        )
        command = REMOTE["build_remote_command"](args)

        self.assertIn("squeue -j 42; tail -3 job.log", command)

    def test_optional_separator_is_not_sent_remotely(self):
        args = REMOTE["parse_args"](["power", "--", "squeue", "-j", "42"])

        self.assertEqual(args.command, ["squeue", "-j", "42"])

    def test_main_hides_password_and_propagates_exit_status(self):
        completed = subprocess.CompletedProcess([], 17)
        with patch.dict(os.environ, {"TAU_PASSWORD": "secret"}, clear=True):
            with patch("subprocess.run", return_value=completed) as run:
                result = REMOTE["main"](["hostname"])

        argv = run.call_args.args[0]
        environment = run.call_args.kwargs["env"]
        self.assertEqual(result, 17)
        self.assertNotIn("secret", argv)
        self.assertEqual(environment["SSHPASS"], "secret")

    def test_password_is_required(self):
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(REMOTE["main"](["power", "hostname"]), 2)


if __name__ == "__main__":
    unittest.main()
