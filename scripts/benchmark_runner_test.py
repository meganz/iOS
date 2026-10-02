#!/usr/bin/env python3
"""Tests for benchmark.sh. Run: python3 scripts/benchmark_runner_test.py

The real script runs with fake xcodebuild, xcrun and python3 commands. They are bash functions exported to the
script, so no file needs an executable bit. The fakes record their arguments, so the tests check what the runner
passes on. The fake python3 runs the real benchmark_ci.py for a skip list, and fakes its simulator lookup.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
RUNNER = os.path.join(HERE, "benchmark.sh")

FAKES = r'''
xcodebuild() {
    case " $* " in
        *" test "*) printf '%s\n' "$@" > "$CALLS/xcodebuild-test.txt"; return "$TEST_STATUS" ;;
        *" -version "*) echo "Xcode 26.4.1" ;;
    esac
}
xcrun() { printf '%s\n' "$@" >> "$CALLS/xcrun.txt"; }
python3() {
    case "$1" in
        *benchmark_ci.py)
            case "$2" in
                simulator) printf '%s\n' "$@" > "$CALLS/simulator.txt"; echo "SIM-NAMED"; return "$SIMULATOR_STATUS" ;;
                *) "$PYTHON" "$@" ;;
            esac ;;
        *) printf '%s\n' "$@" > "$CALLS/reporter.txt"; return 0 ;;
    esac
}
export -f xcodebuild xcrun python3
bash "$RUNNER" "$PACKAGE" --out "$OUT" "$@"
'''


class RunnerTests(unittest.TestCase):
    def run_runner(self, *options, test_status=0, sim=True, skipped=None, simulator_status=0):
        """Returns (exit code, xcodebuild test arguments, reporter arguments, manifest).
        sim: pass --sim SIM-1. skipped: the package's Skipped.json contents. Other calls are in self.calls."""
        with tempfile.TemporaryDirectory() as folder:
            # A path with a space checks the quoting.
            package = os.path.join(folder, "My Package")
            os.mkdir(package)
            with open(os.path.join(package, "Package.swift"), "w") as handle:
                handle.write("// swift-tools-version: 6.0\n")
            if skipped is not None:
                target = os.path.join(package, "Tests", "My PackageBenchmarks")
                os.makedirs(target)
                with open(os.path.join(target, "Skipped.json"), "w") as handle:
                    json.dump(skipped, handle)
            calls = os.path.join(folder, "calls")
            os.mkdir(calls)
            out = os.path.join(folder, "out")
            environment = dict(os.environ, RUNNER=RUNNER, PACKAGE=package, OUT=out, CALLS=calls, TEST_STATUS=str(test_status),
                               SIMULATOR_STATUS=str(simulator_status), PYTHON=sys.executable)
            arguments = (["--sim", "SIM-1"] if sim else []) + list(options)
            result = subprocess.run(["bash", "-c", FAKES, "fakes", *arguments], env=environment, capture_output=True, text=True)
            self.output = result.stdout + result.stderr

            def lines(name):
                path = os.path.join(calls, name)
                if not os.path.isfile(path):
                    return []
                with open(path) as handle:
                    return handle.read().splitlines()

            self.calls = {name: lines(name + ".txt") for name in ("simulator", "xcrun")}
            manifest = {}
            if os.path.isfile(os.path.join(out, "manifest.json")):
                with open(os.path.join(out, "manifest.json")) as handle:
                    manifest = json.load(handle)
            return result.returncode, lines("xcodebuild-test.txt"), lines("reporter.txt"), manifest

    def test_default_is_release_with_testability(self):
        code, build, _, manifest = self.run_runner()
        self.assertEqual(code, 0)
        self.assertIn("-configuration", build)
        self.assertEqual(build[build.index("-configuration") + 1], "Release")
        self.assertIn("ENABLE_TESTABILITY=YES", build)
        self.assertEqual(manifest["configuration"], "Release")

    def test_debug_passes_debug_explicitly(self):
        code, build, _, manifest = self.run_runner("--debug")
        self.assertEqual(code, 0)
        self.assertEqual(build[build.index("-configuration") + 1], "Debug")
        self.assertNotIn("ENABLE_TESTABILITY=YES", build)
        self.assertEqual(manifest["configuration"], "Debug")

    def test_fixed_run_settings_and_selection_are_passed_on(self):
        code, build, reporter, manifest = self.run_runner("--only", "ParsingBenchmarks")
        self.assertEqual(code, 0)
        self.assertIn("-only-testing:My PackageBenchmarks/ParsingBenchmarks", build)
        self.assertEqual(build[build.index("-parallel-testing-enabled") + 1], "NO")
        self.assertEqual(build[build.index("-enableCodeCoverage") + 1], "NO")
        for sanitizer in ("-enableAddressSanitizer", "-enableThreadSanitizer", "-enableUndefinedBehaviorSanitizer"):
            self.assertEqual(build[build.index(sanitizer) + 1], "NO", sanitizer)
        for setting in ("ENABLE_ADDRESS_SANITIZER=NO", "ENABLE_THREAD_SANITIZER=NO", "ENABLE_UNDEFINED_BEHAVIOR_SANITIZER=NO"):
            self.assertIn(setting, build)
        self.assertEqual(reporter[reporter.index("--only") + 1], "ParsingBenchmarks")
        self.assertEqual(manifest["only"], "ParsingBenchmarks")

    def test_failed_build_fails_and_does_not_write_limits(self):
        code, _, reporter, _ = self.run_runner("--write-limits", test_status=65)
        self.assertNotEqual(code, 0)
        self.assertNotIn("--write-limits", reporter)

    def test_passed_build_asks_for_the_limits_write(self):
        code, _, reporter, _ = self.run_runner("--write-limits")
        self.assertEqual(code, 0)
        self.assertIn("--write-limits", reporter)


    # MARK: pinned simulator

    def test_simulator_name_and_os_pick_and_boot_that_simulator(self):
        code, build, _, manifest = self.run_runner("--sim-name", "iPhone 17 Pro", "--sim-os", "26.4", sim=False)
        self.assertEqual(code, 0, self.output)
        self.assertEqual(self.calls["simulator"][2:], ["--name", "iPhone 17 Pro", "--os", "26.4"])
        self.assertEqual(self.calls["xcrun"], ["simctl", "bootstatus", "SIM-NAMED", "-b"])
        self.assertIn("platform=iOS Simulator,id=SIM-NAMED", build)
        self.assertEqual(manifest["simulator"], "SIM-NAMED")

    def test_missing_simulator_runtime_stops_before_the_build(self):
        code, build, _, _ = self.run_runner("--sim-name", "iPhone 17 Pro", "--sim-os", "26.4", sim=False, simulator_status=1)
        self.assertEqual(code, 2, self.output)
        self.assertEqual(build, [])

    def test_simulator_name_needs_an_os_and_no_udid(self):
        for options, sim in ((("--sim-name", "iPhone 17 Pro"), False), (("--sim-name", "iPhone 17 Pro", "--sim-os", "26.4"), True)):
            code, build, _, _ = self.run_runner(*options, sim=sim)
            self.assertEqual(code, 2, self.output)
            self.assertEqual(build, [])

    # MARK: skip list

    def test_skip_list_skips_each_test_and_reaches_the_report(self):
        code, build, reporter, _ = self.run_runner(
            skipped={"ParsingBenchmarks/testSlow": "IOS-1: investigating", "EditorBenchmarks": "IOS-2: flaky"})
        self.assertEqual(code, 0, self.output)
        self.assertIn("-skip-testing:My PackageBenchmarks/EditorBenchmarks", build)
        self.assertIn("-skip-testing:My PackageBenchmarks/ParsingBenchmarks/testSlow", build)
        self.assertTrue(reporter[reporter.index("--skipped") + 1].endswith("Tests/My PackageBenchmarks/Skipped.json"))

    def test_invalid_skip_list_stops_before_the_build(self):
        for skipped in ({"ParsingBenchmarks/testSlow": ""}, ["ParsingBenchmarks/testSlow"]):
            code, build, _, _ = self.run_runner(skipped=skipped)
            self.assertEqual(code, 2, self.output)
            self.assertIn("Invalid skip list", self.output)
            self.assertEqual(build, [])

    def test_no_skip_list_skips_nothing(self):
        code, build, reporter, _ = self.run_runner()
        self.assertEqual(code, 0)
        self.assertFalse(any(argument.startswith("-skip-testing") for argument in build))
        self.assertNotIn("--skipped", reporter)


if __name__ == "__main__":
    unittest.main()
