"""Prove the runner cannot accept silent engine errors or hanging children."""
import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "tools/qa/verify_project.py"
spec = importlib.util.spec_from_file_location("verify_project", RUNNER)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerContract(unittest.TestCase):
    def check_child(self, source, timeout=5):
        with tempfile.TemporaryDirectory(prefix="sdd-runner-") as directory:
            output = Path(directory)
            # run_check normally stores repository-relative log paths.
            original_root = runner.ROOT
            runner.ROOT = output
            try:
                return runner.run_check("probe", [sys.executable, "-c", source], output, timeout)
            finally:
                runner.ROOT = original_root

    def test_error_with_zero_exit_is_failure(self):
        result = self.check_child("import sys; print('SCRIPT ERROR: broken', file=sys.stderr)")
        self.assertEqual(result["exit_code"], 0)
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["errors"], 1)

    def test_nonzero_exit_is_failure(self):
        self.assertEqual(self.check_child("raise SystemExit(3)")["status"], "FAIL")

    def test_timeout_is_failure(self):
        result = self.check_child("import time; time.sleep(10)", timeout=0.1)
        self.assertTrue(result["timed_out"])
        self.assertEqual(result["status"], "FAIL")

    @unittest.skipUnless(os.name == "nt", "Windows PID-tree cleanup contract")
    def test_timeout_closes_descendant_log_handles(self):
        result = self.check_child(
            "import subprocess,sys,time; "
            "subprocess.Popen([sys.executable,'-c','import time; time.sleep(10)']); "
            "time.sleep(10)", timeout=0.5,
        )
        self.assertTrue(result["timed_out"])
        self.assertEqual(result["status"], "FAIL")
        # check_child's TemporaryDirectory cleanup also proves no inherited log
        # handle remains owned by the stopped child's descendants on Windows.

    def test_warning_is_reported_without_hiding_failure(self):
        result = self.check_child("print('WARNING: baseline warning')")
        self.assertEqual(result["warnings"], 1)
        self.assertEqual(result["status"], "PASS")


if __name__ == "__main__":
    unittest.main()
