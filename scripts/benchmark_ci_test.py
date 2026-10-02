#!/usr/bin/env python3
"""Tests for benchmark_ci.py. Run: python3 scripts/benchmark_ci_test.py

The package tests build a small repo tree in a temporary folder. The simulator tests feed `simctl list --json` output.
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = importlib.util.spec_from_file_location("benchmark_ci", os.path.join(HERE, "benchmark_ci.py"))
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


def write(root, path, text=""):
    full = os.path.join(root, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as handle:
        handle.write(text)


def manifest(*paths):
    dependencies = ", ".join(f'.package(path: "{path}")' for path in paths)
    return f"// swift-tools-version: 6.0\nlet package = Package(dependencies: [{dependencies}])\n"


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.root = self.folder.name
        # Markdown opts in and depends on Foundation, which depends on a package inside a submodule.
        write(self.root, "Modules/UI/Markdown/Package.swift", manifest("../../Infrastructure/Foundation"))
        write(self.root, "Modules/UI/Markdown/Tests/MarkdownBenchmarks/Limits.json", "{}")
        write(self.root, "Modules/Infrastructure/Foundation/Package.swift", manifest("../../Shared/Swift"))
        write(self.root, "Modules/Shared/Swift/Package.swift", manifest())
        # Chat has a benchmark target but no Limits.json, so it has not opted in.
        write(self.root, "Modules/Features/Chat/Package.swift", manifest())
        write(self.root, "Modules/Features/Chat/Tests/ChatBenchmarks/ChatBenchmarks.swift")
        # A Limits.json under a build folder is not a package.
        write(self.root, "Modules/UI/Markdown/.build/Copy/Package.swift", manifest())
        write(self.root, "Modules/UI/Markdown/.build/Copy/Tests/CopyBenchmarks/Limits.json", "{}")

    def tearDown(self):
        self.folder.cleanup()

    def selected(self, *changed):
        return ci.affected(self.root, ci.find_opted_in(self.root), list(changed))[0]

    def test_only_packages_with_limits_opt_in(self):
        self.assertEqual(ci.find_opted_in(self.root), ["Modules/UI/Markdown"])

    def test_a_change_in_the_package_selects_it(self):
        self.assertEqual(self.selected("Modules/UI/Markdown/Sources/Parser.swift"), ["Modules/UI/Markdown"])

    def test_a_change_in_a_local_dependency_selects_it(self):
        self.assertEqual(self.selected("Modules/Infrastructure/Foundation/Sources/A.swift"), ["Modules/UI/Markdown"])
        self.assertEqual(self.selected("Modules/Shared/Swift/Sources/B.swift"), ["Modules/UI/Markdown"])

    def test_a_submodule_change_that_holds_a_dependency_selects_it(self):
        self.assertEqual(self.selected("Modules/Shared"), ["Modules/UI/Markdown"])

    def test_an_unrelated_change_selects_nothing(self):
        self.assertEqual(self.selected("Modules/Features/Chat/Sources/C.swift", "iMEGA/AppDelegate.swift"), [])

    def test_a_folder_with_a_common_prefix_is_not_the_package(self):
        self.assertEqual(self.selected("Modules/UI/MarkdownDemo/App.swift"), [])

    def test_a_tooling_change_selects_every_opted_in_package(self):
        for path in ("scripts/benchmark.sh", "scripts/benchmark_report.py", "jenkinsfile/benchmarks.groovy",
                     "scripts/fixtures/benchmark_report/two-configurations/tests.json"):
            selected, reason = ci.affected(self.root, ci.find_opted_in(self.root), [path])
            self.assertEqual(selected, ["Modules/UI/Markdown"], path)
            self.assertIn(path, reason)

    def test_dependency_cycles_end(self):
        write(self.root, "Modules/Shared/Swift/Package.swift", manifest("../../UI/Markdown"))
        self.assertEqual(len(ci.local_dependencies(self.root, "Modules/UI/Markdown")), 3)

    def test_base_mode_reads_the_git_diff(self):
        def git(*arguments):
            subprocess.run(["git", "-C", self.root, *arguments], check=True, capture_output=True)
        git("init", "-q", "-b", "main")
        git("-c", "user.name=t", "-c", "user.email=t@t", "add", ".")
        git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "base")
        git("tag", "base")
        write(self.root, "Modules/Shared/Swift/Sources/B.swift", "let b = 1\n")
        git("-c", "user.name=t", "-c", "user.email=t@t", "add", ".")
        git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "change")
        output = subprocess.run([sys.executable, os.path.join(HERE, "benchmark_ci.py"), "packages", "--repo-root", self.root,
                                 "--base", "base"], capture_output=True, text=True, check=True)
        self.assertEqual(output.stdout, "Modules/UI/Markdown\n")


RUNTIMES = {"runtimes": [
    {"platform": "iOS", "version": "18.6", "identifier": "iOS-18-6", "isAvailable": True},
    {"platform": "iOS", "version": "26.4.1", "identifier": "iOS-26-4", "isAvailable": True},
    {"platform": "iOS", "version": "26.40", "identifier": "iOS-26-40", "isAvailable": True},
    {"platform": "tvOS", "version": "26.4", "identifier": "tvOS-26-4", "isAvailable": True},
]}
DEVICES = {"devices": {"iOS-26-4": [
    {"name": "iPhone 17", "udid": "A", "isAvailable": True},
    {"name": "iPhone 17 Pro", "udid": "B", "isAvailable": False},
    {"name": "iPhone 17 Pro", "udid": "C", "isAvailable": True},
]}}


class SimulatorTests(unittest.TestCase):
    def test_runtime_matches_the_version_or_a_patch_of_it(self):
        self.assertEqual(ci.pick_runtime(RUNTIMES, "26.4")["identifier"], "iOS-26-4")
        self.assertEqual(ci.pick_runtime(RUNTIMES, "26.4.1")["identifier"], "iOS-26-4")

    def test_no_other_os_is_picked(self):
        self.assertIsNone(ci.pick_runtime(RUNTIMES, "26.5"))
        self.assertIsNone(ci.pick_runtime(RUNTIMES, "26"))

    def test_device_must_match_the_name_and_be_available(self):
        self.assertEqual(ci.pick_device(DEVICES, "iOS-26-4", "iPhone 17 Pro"), "C")
        self.assertIsNone(ci.pick_device(DEVICES, "iOS-26-4", "iPhone 17 Pro Max"))
        self.assertIsNone(ci.pick_device(DEVICES, "iOS-18-6", "iPhone 17 Pro"))


class SkippedTests(unittest.TestCase):
    def run_skipped(self, contents):
        with tempfile.TemporaryDirectory() as folder:
            path = os.path.join(folder, "Skipped.json")
            with open(path, "w") as handle:
                json.dump(contents, handle)
            return subprocess.run([sys.executable, os.path.join(HERE, "benchmark_ci.py"), "skipped", path],
                                  capture_output=True, text=True)

    def test_prints_the_skipped_tests(self):
        result = self.run_skipped({"B/testTwo": "IOS-2: why", "A": "IOS-1: why"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "A\nB/testTwo\n")

    def test_rejects_an_entry_without_a_reason(self):
        for contents in ({"A/test": ""}, {"A/test": "  "}, {"A/test": 1}, ["A/test"], {"A test": "why"}):
            result = self.run_skipped(contents)
            self.assertNotEqual(result.returncode, 0, contents)
            self.assertIn("Invalid skip list", result.stderr)


if __name__ == "__main__":
    unittest.main()
