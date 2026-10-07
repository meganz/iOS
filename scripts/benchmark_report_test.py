#!/usr/bin/env python3
"""Tests for benchmark_report.py. Run: python3 scripts/benchmark_report_test.py

The tests feed raw xcresulttool JSON through the real loader, so parsing and run identity are covered too.
"""
import contextlib
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = importlib.util.spec_from_file_location("benchmark_report", os.path.join(HERE, "benchmark_report.py"))
report = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(report)

DEVICE = {"deviceId": "SIM-1", "deviceName": "iPhone 17", "modelName": "iPhone 17", "osVersion": "26.4.1", "platform": "iOS Simulator"}
CONFIGURATION = {"configurationId": "1", "configurationName": "Test Scheme Action"}


def metric(name, values, unit="s", polarity=None, identifier="clock"):
    record = {"displayName": name, "unitOfMeasurement": unit, "measurements": values, "identifier": identifier}
    if polarity:
        record["polarity"] = polarity
    return record


def bundle(tests, results=None, device=DEVICE, configuration=CONFIGURATION, extra_runs=(), system_failures=(), repetitions=None,
           configurations=None, devices=None):
    """Raw JSON like xcresulttool prints it. tests: {test: [metric records]}. results default to Passed.
    system_failures: names of runner errors, put in a "System Failures" suite like Xcode does.
    repetitions: {test: [attempt results]}, put as "Repetition" children like a retrying test plan does.
    configurations and devices: the tests tree's lists, by default the one configuration and device of the runs."""
    if results is None:
        results = {test: "Passed" for test in tests}
    metrics_json = []
    for test, records in tests.items():
        runs = [{"device": device, "testPlanConfiguration": configuration, "metrics": records}]
        runs += [run for run_test, run in extra_runs if run_test == test]
        metrics_json.append({"testIdentifier": test + "()", "testRuns": runs})
    nodes = [{"nodeType": "Test Case", "nodeIdentifier": test + "()", "result": result} for test, result in results.items()]
    for node in nodes:
        attempts = (repetitions or {}).get(node["nodeIdentifier"][:-2], [])
        node["children"] = [{"nodeType": "Repetition", "name": f"Run {index + 1}", "result": result} for index, result in enumerate(attempts)]
    if system_failures:
        errors = [{"nodeType": "Test Case", "name": name, "nodeIdentifier": name, "result": "Failed"} for name in system_failures]
        nodes.append({"nodeType": "Test Suite", "name": "System Failures", "result": "Failed", "children": errors})
    tests_json = {"devices": devices or [device], "testPlanConfigurations": configurations or [configuration],
                  "testNodes": [{"nodeType": "Unit test bundle", "children": nodes}]}
    return {"metrics": metrics_json, "tests": tests_json}


class ReportTests(unittest.TestCase):
    def run_report(self, candidate, base=None, limits=None, extra=(), manifests=(None, None), write_limits=None, existing_limits=None,
                   skipped=None):
        """Runs main() with injected xcresulttool output. Returns (exit code, last line, output, limits file text)."""
        with tempfile.TemporaryDirectory() as folder:
            paths = {}
            for name, contents, manifest in (("candidate", candidate, manifests[0]), ("base", base, manifests[1])):
                if contents is None:
                    continue
                bundle_folder = os.path.join(folder, name)
                os.mkdir(bundle_folder)
                path = os.path.join(bundle_folder, "result.xcresult")
                os.mkdir(path)
                paths[path] = contents
                if manifest is not None:
                    with open(os.path.join(bundle_folder, "manifest.json"), "w") as handle:
                        json.dump(manifest, handle)
            argv = ["benchmark_report.py", os.path.join(folder, "candidate", "result.xcresult")]
            if limits is not None:
                limits_path = os.path.join(folder, "Limits.json")
                with open(limits_path, "w") as handle:
                    json.dump(limits, handle)
                argv += ["--limits", limits_path]
            if skipped is not None:
                skipped_path = os.path.join(folder, "Skipped.json")
                with open(skipped_path, "w") as handle:
                    json.dump(skipped, handle)
                argv += ["--skipped", skipped_path]
            limits_file = os.path.join(folder, "Written.json")
            if write_limits:
                if existing_limits is not None:
                    with open(limits_file, "w") as handle:
                        json.dump(existing_limits, handle)
                argv += ["--write-limits", limits_file]
            if base is not None:
                argv += ["--base", os.path.join(folder, "base", "result.xcresult")]
            argv += [limits_file if item == "@written" else item for item in extra]
            output = io.StringIO()
            code = 0
            # Patched only for this call, so one test cannot leak its fake into the next.
            with mock.patch.object(report, "xcresulttool", lambda subcommand, xcresult: paths[xcresult][subcommand]), \
                    mock.patch.object(sys, "argv", argv), \
                    contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                try:
                    report.main()
                except SystemExit as error:
                    code = error.code or 0
            text = output.getvalue()
            written = None
            if os.path.isfile(limits_file):
                with open(limits_file) as handle:
                    written = handle.read()
            return code, text.strip().splitlines()[-1] if text.strip() else "", text, written

    # MARK: grouping

    def test_groups_by_class_with_passed_rows_folded(self):
        _, _, text, _ = self.run_report(
            bundle({"Slow/t": [metric("Clock", [3, 3])], "Fast/t": [metric("Clock", [1, 1])]}),
            limits={"Slow/t": {"Clock": 2}, "Fast/t": {"Clock": 2}})
        slow, fast = text.index("**Slow** FAILED"), text.index("**Fast** passed")
        self.assertIn("OVER LIMIT", text[slow:fast] if slow < fast else text[slow:])
        self.assertEqual(text.count("<details>"), 1)
        self.assertEqual(text.count("<summary>Passed (1)</summary>"), 1)
        folded = text[text.index("<details>"):text.index("</details>")]
        self.assertIn("Fast/t", folded)
        self.assertNotIn("Slow/t", folded)

    # MARK: limits

    def test_passes_within_limits(self):
        code, last, _, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 0)
        self.assertTrue(last.startswith("OK: 1 metrics"), last)

    def test_over_limit_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [3, 3])]}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("over limit 2", text)

    def test_missing_required_metric_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": 2, "Peak Heap Growth": 100}})
        self.assertEqual(code, 1)
        self.assertIn("P/t Peak Heap Growth: no measurement", text)

    def test_missing_required_test_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": 2}, "P/big": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("P/big: did not run", text)

    def test_only_scopes_the_required_tests(self):
        code, last, _, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": 2}, "Q/other": {"Clock": 2}}, extra=["--only", "P"])
        self.assertEqual(code, 0, last)

    # MARK: usable bundle

    def test_skipped_test_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, results={"P/t": "Passed", "P/u": "Skipped"}))
        self.assertEqual(code, 1)
        self.assertIn("candidate P/u: skipped", text)

    def test_failed_test_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, results={"P/t": "Failed"}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("candidate P/t: failed", text)

    def test_measured_test_without_result_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, results={"P/other": "Passed"}))
        self.assertEqual(code, 1)
        self.assertIn("P/t: measured, but no test result", text)

    def test_too_few_samples_fail(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1])]}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("1 samples, at least 2 needed", text)

    def test_empty_samples_fail(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [])]}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("0 samples", text)

    def test_nan_sample_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [float("nan"), 1])]}), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("not a finite number", text)

    def test_two_runs_in_one_bundle_fail(self):
        other = {"device": {"deviceId": "SIM-2", "deviceName": "iPhone 17"}, "testPlanConfiguration": {"configurationName": "Other"},
                 "metrics": [metric("Clock", [9, 9])]}
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, extra_runs=[("P/t", other)]), limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 1)
        self.assertIn("2 runs in one bundle, not pooled", text)

    def test_no_limits_and_no_base_is_collection_only(self):
        code, last, _, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}))
        self.assertEqual(code, 0)
        self.assertTrue(last.startswith("COLLECTION ONLY"), last)

    # MARK: base

    def gate(self, candidate, base, extra=(), manifests=None):
        manifest = {"configuration": "Release", "xcode": "26.4.1", "host": "Mac", "cpu": "M3"}
        return self.run_report(candidate, base=base, extra=["--max-regression", "20", *extra],
                               manifests=manifests or (manifest, manifest))

    def test_no_regression_passes(self):
        code, last, _, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}))
        self.assertEqual(code, 0, last)

    def test_regression_against_base_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [2, 2])]}), bundle({"P/t": [metric("Clock", [1, 1])]}))
        self.assertEqual(code, 1)
        self.assertIn("+100.0% against the base", text)

    def test_empty_base_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({}))
        self.assertEqual(code, 1)
        self.assertIn("base: no performance metrics", text)

    def test_base_without_the_metric_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("CPU", [1, 1], identifier="cpu")]}))
        self.assertEqual(code, 1)
        self.assertIn("P/t Clock: no base measurement", text)

    def test_base_without_the_metric_is_new_when_allowed(self):
        # The base metric CPU is gone from the candidate too, so that side needs its own allowance.
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("CPU", [1, 1], identifier="cpu")]}),
            extra=["--allow-missing-base", "--allow-removed"])
        self.assertEqual(code, 0, text)
        self.assertIn("| NEW |", text)

    def test_nan_base_sample_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [float("nan"), 1])]}))
        self.assertEqual(code, 1)
        self.assertIn("base P/t Clock: a sample is not a finite number", text)

    def test_failed_base_test_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}, results={"P/t": "Failed"}))
        self.assertEqual(code, 1)
        self.assertIn("base P/t: failed", text)

    def test_zero_base_with_growth_fails(self):
        code, _, text, _ = self.gate(
            bundle({"U/t": [metric("Late Frames", [5, 5], unit="count", identifier="late")]}),
            bundle({"U/t": [metric("Late Frames", [0, 0], unit="count", identifier="late")]}))
        self.assertEqual(code, 1)
        self.assertIn("against a base of 0", text)

    def test_zero_base_within_allowance_passes(self):
        code, last, _, _ = self.gate(
            bundle({"U/t": [metric("Late Frames", [1, 1], unit="count", identifier="late")]}),
            bundle({"U/t": [metric("Late Frames", [0, 0], unit="count", identifier="late")]}), extra=["--zero-allowance", "2"])
        self.assertEqual(code, 0, last)

    def test_unspecified_polarity_is_not_gated(self):
        code, last, _, _ = self.gate(
            bundle({"P/t": [metric("Samples", [200, 200], unit="count", polarity="unspecified", identifier="s")]}),
            bundle({"P/t": [metric("Samples", [100, 100], unit="count", polarity="unspecified", identifier="s")]}))
        self.assertEqual(code, 0, last)

    def test_unit_mismatch_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Peak", [1, 1], unit="MiB")]}), bundle({"P/t": [metric("Peak", [1, 1], unit="kB")]}))
        self.assertEqual(code, 1)
        self.assertIn("unit MiB against base unit kB", text)

    def test_identifier_mismatch_fails(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Peak", [1, 1], identifier="new")]}), bundle({"P/t": [metric("Peak", [1, 1], identifier="old")]}))
        self.assertEqual(code, 1)
        self.assertIn("identifier new against base old", text)

    def test_max_regression_needs_base(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), extra=["--max-regression", "20"])
        self.assertEqual(code, 2)
        self.assertIn("needs --base", text)

    def test_different_device_fails(self):
        pro = dict(DEVICE, deviceId="SIM-2", deviceName="iPhone 17 Pro", modelName="iPhone 17 Pro")
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}, device=pro))
        self.assertEqual(code, 1)
        self.assertIn("environment: device", text)

    def test_different_configuration_fails(self):
        release = {"configuration": "Release", "xcode": "26.4.1", "host": "Mac", "cpu": "M3"}
        debug = dict(release, configuration="Debug")
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}), manifests=(release, debug))
        self.assertEqual(code, 1)
        self.assertIn("configuration 'Release' against base 'Debug'", text)

    def test_missing_manifest_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}), manifests=(None, None))
        self.assertEqual(code, 1)
        self.assertIn("no manifest.json", text)

    def test_environment_mismatch_can_be_allowed(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}),
            manifests=(None, None), extra=["--allow-environment-mismatch"])
        self.assertEqual(code, 0, text)
        self.assertIn("NOTE: environment", text)

    # MARK: write limits

    def test_write_limits_skips_undirected_and_floors_counts(self):
        code, _, text, written = self.run_report(bundle({"P/t": [
            metric("Clock", [1.0, 1.0]),
            metric("Peak Heap Growth", [10, 10], unit="MiB", identifier="heap"),
            metric("Stalls", [0, 0], unit="count", identifier="stalls"),
            metric("Samples", [100, 100], unit="count", polarity="unspecified", identifier="samples"),
        ]}), write_limits=True)
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 3.0, "Peak Heap Growth": 15.0, "Stalls": 2}})

    def test_write_limits_ignores_old_numbers_but_keeps_old_coverage(self):
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [5, 5])]}), write_limits=True, existing_limits={"P/t": {"Clock": 2}})
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 15.0}})

    def test_failed_run_leaves_limits_unchanged(self):
        existing = {"P/t": {"Clock": 2}, "P/fail": {"Clock": 2}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "P/fail": [metric("Clock", [1, 1])]}, results={"P/t": "Passed", "P/fail": "Failed"}),
            write_limits=True, existing_limits=existing)
        self.assertEqual(code, 1)
        self.assertIn("Limits file not written", text)
        self.assertEqual(json.loads(written), existing)

    def test_missing_covered_test_leaves_limits_unchanged(self):
        existing = {"P/t": {"Clock": 2}, "P/gone": {"Clock": 2}}
        code, _, text, written = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), write_limits=True, existing_limits=existing)
        self.assertEqual(code, 1)
        self.assertIn("P/gone: did not run", text)
        self.assertEqual(json.loads(written), existing)

    def test_partial_write_keeps_unselected_entries(self):
        existing = {"P/t": {"Clock": 2}, "Q/other": {"Clock": 7}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}), write_limits=True, existing_limits=existing, extra=["--only", "P/t"])
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 3.0}, "Q/other": {"Clock": 7}})

    # MARK: options, coverage and new tests against the base

    def test_missing_explicit_limits_file_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), extra=["--limits", "/nonexistent/Limits.json"])
        self.assertEqual(code, 1)
        self.assertIn("no limits file at /nonexistent/Limits.json", text)

    def test_new_limits_file_through_both_options_passes(self):
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}), write_limits=True, extra=["--limits", "@written"])
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 3.0}})

    def test_base_test_missing_from_candidate_fails(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])], "P/gone": [metric("Clock", [1, 1])]}))
        self.assertEqual(code, 1)
        self.assertIn("P/gone Clock: in the base, not in the candidate", text)

    def test_base_metric_missing_from_candidate_fails(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1]), metric("Heap", [1, 1], unit="MiB", identifier="heap")]}))
        self.assertEqual(code, 1)
        self.assertIn("P/t Heap: in the base, not in the candidate", text)

    def test_removed_metric_can_be_allowed(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1]), metric("Heap", [1, 1], unit="MiB", identifier="heap")]}),
            extra=["--allow-removed"])
        self.assertEqual(code, 0, text)
        self.assertIn("| REMOVED |", text)

    def test_removed_undirected_metric_is_not_required(self):
        code, last, _, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}),
            bundle({"P/t": [metric("Clock", [1, 1]), metric("Samples", [5, 5], unit="count", polarity="unspecified", identifier="s")]}))
        self.assertEqual(code, 0, last)

    def test_run_record_without_metrics_fails(self):
        code, _, text, _ = self.gate(bundle({"P/t": []}), bundle({"P/t": [metric("Clock", [1, 1])]}))
        self.assertEqual(code, 1)
        self.assertIn("candidate: no performance metrics", text)

    def test_only_matching_no_test_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), extra=["--only", "Typo/noSuchTest"])
        self.assertEqual(code, 1)
        self.assertIn("no test matches --only Typo/noSuchTest", text)

    def test_partial_write_from_a_full_bundle_keeps_unselected_entries(self):
        existing = {"P/t": {"Clock": 2}, "Q/other": {"Clock": 7}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "Q/other": [metric("Clock", [9, 9])]}),
            write_limits=True, existing_limits=existing, extra=["--only", "P/t"])
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 3.0}, "Q/other": {"Clock": 7}})

    def test_incomplete_manifest_fails(self):
        partial = {"commit": "abc"}
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}), bundle({"P/t": [metric("Clock", [1, 1])]}), manifests=(partial, partial))
        self.assertEqual(code, 1)
        self.assertIn("configuration unknown", text)

    def test_device_without_model_fails(self):
        bare = {"deviceId": "SIM-1", "deviceName": "iPhone 17"}
        code, _, text, _ = self.gate(bundle({"P/t": [metric("Clock", [1, 1])]}, device=bare), bundle({"P/t": [metric("Clock", [1, 1])]}, device=bare))
        self.assertEqual(code, 1)
        self.assertIn("device model, OS or platform unknown", text)

    def test_nan_limit_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [100, 100])]}), limits={"P/t": {"Clock": float("nan")}})
        self.assertEqual(code, 1)
        self.assertIn("the limit nan is not a finite number", text)

    def test_nan_max_regression_is_rejected(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [100, 100])]}), base=bundle({"P/t": [metric("Clock", [1, 1])]}),
                                           extra=["--max-regression", "nan"])
        self.assertEqual(code, 2)
        self.assertIn("finite number", text)

    def test_min_samples_must_be_positive(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), extra=["--min-samples", "0"])
        self.assertEqual(code, 2)
        self.assertIn("at least 1", text)

    def test_new_test_selected_alone_is_new_when_allowed(self):
        code, _, text, _ = self.gate(
            bundle({"P/new": [metric("Clock", [1, 1])]}), bundle({"P/old": [metric("Clock", [1, 1])]}),
            extra=["--only", "P/new", "--allow-missing-base"])
        self.assertEqual(code, 0, text)
        self.assertIn("| NEW |", text)

    def test_new_class_selected_alone_is_new_when_allowed(self):
        code, _, text, _ = self.gate(
            bundle({"Q/new": [metric("Clock", [1, 1])]}), bundle({"P/old": [metric("Clock", [1, 1])]}),
            extra=["--only", "Q", "--allow-missing-base"])
        self.assertEqual(code, 0, text)

    def test_new_test_selected_alone_fails_without_the_allowance(self):
        code, _, text, _ = self.gate(
            bundle({"P/new": [metric("Clock", [1, 1])]}), bundle({"P/old": [metric("Clock", [1, 1])]}), extra=["--only", "P/new"])
        self.assertEqual(code, 1)
        self.assertIn("base: no test matches --only P/new", text)

    def test_empty_base_still_fails_with_the_allowance(self):
        code, _, text, _ = self.gate(
            bundle({"P/new": [metric("Clock", [1, 1])]}), bundle({}), extra=["--only", "P/new", "--allow-missing-base"])
        self.assertEqual(code, 1)
        self.assertIn("base: no performance metrics", text)

    def new_test_against(self, base):
        return self.gate(bundle({"P/new": [metric("Clock", [1, 1])]}), base, extra=["--only", "P/new", "--allow-missing-base"])

    def test_base_run_without_metrics_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.new_test_against(bundle({"P/old": []}))
        self.assertEqual(code, 1)
        self.assertIn("base: no performance metrics", text)

    def test_base_with_empty_samples_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.new_test_against(bundle({"P/old": [metric("Clock", [])]}))
        self.assertEqual(code, 1)
        self.assertIn("base P/old Clock: 0 samples", text)

    def test_base_with_nan_sample_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.new_test_against(bundle({"P/old": [metric("Clock", [float("nan"), 1])]}))
        self.assertEqual(code, 1)
        self.assertIn("base P/old Clock: a sample is not a finite number", text)

    def test_failed_base_test_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.new_test_against(bundle({"P/old": [metric("Clock", [1, 1])]}, results={"P/old": "Failed"}))
        self.assertEqual(code, 1)
        self.assertIn("base P/old: failed", text)

    def test_base_measurement_without_result_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.new_test_against(bundle({"P/old": [metric("Clock", [1, 1])]}, results={"P/other": "Passed"}))
        self.assertEqual(code, 1)
        self.assertIn("base P/old: measured, but no test result", text)

    def test_duplicate_base_records_fail_for_a_selected_new_test(self):
        again = {"device": DEVICE, "testPlanConfiguration": CONFIGURATION, "metrics": [metric("Clock", [9, 9])]}
        code, _, text, _ = self.new_test_against(bundle({"P/old": [metric("Clock", [1, 1])]}, extra_runs=[("P/old", again)]))
        self.assertEqual(code, 1)
        self.assertIn("base P/old: 2 run records for one test", text)

    # MARK: direction, assertion-only selections and run records

    def test_negative_base_that_gets_worse_fails(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Memory Physical", [100, 100], unit="kB", identifier="mem")]}),
            bundle({"P/t": [metric("Memory Physical", [-100, -100], unit="kB", identifier="mem")]}))
        self.assertEqual(code, 1)
        self.assertIn("worse by 200.00", text)

    def test_negative_base_that_gets_better_passes(self):
        code, last, _, _ = self.gate(
            bundle({"P/t": [metric("Memory Physical", [-200, -200], unit="kB", identifier="mem")]}),
            bundle({"P/t": [metric("Memory Physical", [-100, -100], unit="kB", identifier="mem")]}))
        self.assertEqual(code, 0, last)

    def test_prefers_larger_metric_that_drops_fails(self):
        # "prefers larger" is the spelling xcresulttool writes.
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Frame Rate", [50, 50], unit="fps", polarity="prefers larger", identifier="fps")]}),
            bundle({"P/t": [metric("Frame Rate", [100, 100], unit="fps", polarity="prefers larger", identifier="fps")]}))
        self.assertEqual(code, 1)
        self.assertIn("-50.0% against the base", text)

    def test_prefers_larger_metric_that_grows_passes(self):
        code, last, _, _ = self.gate(
            bundle({"P/t": [metric("Frame Rate", [150, 150], unit="fps", polarity="prefers larger", identifier="fps")]}),
            bundle({"P/t": [metric("Frame Rate", [100, 100], unit="fps", polarity="prefers larger", identifier="fps")]}))
        self.assertEqual(code, 0, last)

    def test_separate_limits_file_is_enforced_while_writing(self):
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [100, 100])]}), limits={"P/t": {"Clock": 2}}, write_limits=True)
        self.assertEqual(code, 1)
        self.assertIn("over limit 2", text)
        self.assertIsNone(written)

    def test_assertion_only_selection_passes(self):
        # Like xcresulttool: the assertion-only test has a result but no run record in the metrics JSON.
        code, last, _, _ = self.run_report(
            bundle({"P/measured": [metric("Clock", [1, 1])]}, results={"P/measured": "Passed", "P/check": "Passed"}),
            extra=["--only", "P/check"])
        self.assertEqual(code, 0, last)
        self.assertTrue(last.startswith("ASSERTIONS ONLY: 1 selected tests passed"), last)

    def test_assertion_only_selection_named_in_limits_fails(self):
        code, _, text, _ = self.run_report(
            bundle({"P/measured": [metric("Clock", [1, 1])], "P/check": []}), limits={"P/check": {"Clock": 2}}, extra=["--only", "P/check"])
        self.assertEqual(code, 1)
        self.assertIn("P/check Clock: no measurement", text)

    def test_failed_assertion_only_selection_fails(self):
        code, _, text, _ = self.run_report(
            bundle({"P/measured": [metric("Clock", [1, 1])]}, results={"P/measured": "Passed", "P/check": "Failed"}),
            extra=["--only", "P/check"])
        self.assertEqual(code, 1)
        self.assertIn("candidate P/check: failed", text)

    def test_assertion_only_run_with_an_empty_metrics_array_passes(self):
        # A run of one assertion test alone: xcresulttool prints [] for the metrics.
        code, last, _, _ = self.run_report(bundle({}, results={"P/check": "Passed"}), extra=["--only", "P/check"])
        self.assertEqual(code, 0, last)
        self.assertTrue(last.startswith("ASSERTIONS ONLY: 1 selected tests passed"), last)

    def test_assertion_only_run_that_failed_fails(self):
        code, _, text, _ = self.run_report(bundle({}, results={"P/check": "Failed"}), extra=["--only", "P/check"])
        self.assertEqual(code, 1)
        self.assertIn("candidate P/check: failed", text)

    def test_empty_metrics_without_a_selection_still_fails(self):
        code, _, text, _ = self.run_report(bundle({}, results={"P/check": "Passed"}))
        self.assertEqual(code, 1)
        self.assertIn("no performance metrics", text)

    def test_explicit_limit_on_an_undirected_metric_is_ignored_with_a_note(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1]), metric("Peak Footprint", [33, 34], unit="MiB", polarity="unspecified", identifier="fp")]}),
            limits={"P/t": {"Clock": 2, "Peak Footprint": 30}})
        self.assertEqual(code, 0, text)
        self.assertIn("NOTE: P/t Peak Footprint: the limit 30 is ignored, this metric has no direction", text)

    def test_two_records_for_one_test_fail(self):
        again = {"device": DEVICE, "testPlanConfiguration": CONFIGURATION, "metrics": [metric("Clock", [9, 9])]}
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, extra_runs=[("P/t", again)]), limits={"P/t": {"Clock": 6}})
        self.assertEqual(code, 1)
        self.assertIn("2 run records for one test, not pooled", text)


    # MARK: runner errors

    def test_runner_error_fails_a_selected_class_and_keeps_the_limits(self):
        existing = {"P/t": {"Clock": 10}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}, system_failures=["xctest (85137) encountered an error"]),
            write_limits=True, existing_limits=existing, extra=["--only", "P"])
        self.assertEqual(code, 1, text)
        self.assertIn("candidate: runner error: xctest (85137) encountered an error", text)
        self.assertEqual(json.loads(written), existing)

    def test_runner_error_fails_a_selected_test(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}, system_failures=["xctest (1) encountered an error"]),
            limits={"P/t": {"Clock": 10}}, extra=["--only", "P/t"])
        self.assertEqual(code, 1, text)
        self.assertIn("candidate: runner error", text)

    def test_runner_error_fails_an_assertion_only_selection(self):
        code, _, text, _ = self.run_report(
            bundle({}, results={"P/check": "Passed"}, system_failures=["xctest (1) encountered an error"]), extra=["--only", "P/check"])
        self.assertEqual(code, 1, text)
        self.assertIn("candidate: runner error", text)

    def test_runner_error_without_a_selection_is_reported_once(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}, system_failures=["xctest (1) encountered an error"]), limits={"P/t": {"Clock": 10}})
        self.assertEqual(code, 1, text)
        self.assertEqual(text.count("encountered an error"), 1, text)

    def test_runner_error_in_the_base_fails_the_gate(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}),
            bundle({"P/t": [metric("Clock", [1, 1])]}, system_failures=["xctest (2) encountered an error"]),
            extra=["--only", "P"])
        self.assertEqual(code, 1, text)
        self.assertIn("base: runner error: xctest (2) encountered an error", text)

    def test_runner_error_in_the_base_fails_for_a_selected_new_test(self):
        code, _, text, _ = self.gate(
            bundle({"P/new": [metric("Clock", [1, 1])]}),
            bundle({"P/t": [metric("Clock", [1, 1])]}, system_failures=["xctest (2) encountered an error"]),
            extra=["--only", "P/new", "--allow-missing-base"])
        self.assertEqual(code, 1, text)
        self.assertEqual(text.count("base: runner error"), 1, text)

    def test_failed_unselected_test_still_passes_a_selection(self):
        code, last, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "Q/t": [metric("Clock", [1, 1])]}, results={"P/t": "Passed", "Q/t": "Failed"}),
            limits={"P/t": {"Clock": 10}}, extra=["--only", "P"])
        self.assertEqual(code, 0, text)
        self.assertTrue(last.startswith("OK: 1 metrics"), last)

    # MARK: metrics that prefer larger values

    def throughput(self, value):
        return bundle({"P/t": [metric("Throughput", [value, value], unit="fps", polarity="prefers larger", identifier="fps")]})

    def test_write_limits_gives_a_minimum_to_a_metric_that_prefers_larger_values(self):
        code, _, text, written = self.run_report(self.throughput(100), write_limits=True)
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Throughput": {"min": 33.33}}})

    def test_write_limits_minimum_for_memory_counts_and_negative_averages(self):
        code, _, text, written = self.run_report(bundle({"P/t": [
            metric("Free Memory", [90, 90], unit="MiB", polarity="prefers larger", identifier="free"),
            metric("Items", [10, 10], unit="count", polarity="prefers larger", identifier="items"),
            metric("Score", [-10, -10], unit="pt", polarity="prefers larger", identifier="score"),
        ]}), write_limits=True)
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Free Memory": {"min": 60.0}, "Items": {"min": 3}, "Score": {"min": -30.0}}})

    def test_minimum_round_trip_passes_unchanged_and_better_and_fails_worse(self):
        _, _, _, written = self.run_report(self.throughput(100), write_limits=True)
        limits = json.loads(written)
        for value in (100, 400):
            code, last, text, _ = self.run_report(self.throughput(value), limits=limits)
            self.assertEqual(code, 0, text)
            self.assertTrue(last.startswith("OK: 1 metrics"), last)
        code, _, text, _ = self.run_report(self.throughput(10), limits=limits)
        self.assertEqual(code, 1, text)
        self.assertIn("P/t Throughput: average 10.00 under the minimum 33.33", text)
        self.assertIn("| min 33.33 | UNDER LIMIT |", text)

    def test_minimum_exactly_at_the_limit_passes(self):
        code, _, text, _ = self.run_report(self.throughput(33.33), limits={"P/t": {"Throughput": {"min": 33.33}}})
        self.assertEqual(code, 0, text)

    def test_plain_limit_on_a_metric_that_prefers_larger_values_fails(self):
        for value in (10, 100, 400):
            code, _, text, _ = self.run_report(self.throughput(value), limits={"P/t": {"Throughput": 300}})
            self.assertEqual(code, 1, text)
            self.assertIn("P/t Throughput: a plain limit is a maximum, but this metric prefers larger values", text)
            self.assertIn("WRONG LIMIT", text)

    def test_minimum_on_a_metric_that_prefers_smaller_values_fails(self):
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": {"min": 0.5}}})
        self.assertEqual(code, 1, text)
        self.assertIn("P/t Clock: a minimum limit, but this metric prefers smaller values", text)

    def test_malformed_minimum_fails(self):
        for limit in ({"min": "33"}, {"max": 33}, {"min": float("nan")}, {"min": 33, "max": 99}, {"min": True}):
            code, _, text, _ = self.run_report(self.throughput(100), limits={"P/t": {"Throughput": limit}})
            self.assertEqual(code, 1, text)
            self.assertIn("is not a finite number or", text)

    # MARK: shared display names

    def test_metrics_sharing_a_display_name_fail(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Parse Time", [1, 1], identifier="small"), metric("Parse Time", [100, 100], identifier="large")]}),
            limits={"P/t": {"Parse Time": 60}})
        self.assertEqual(code, 1, text)
        self.assertIn("candidate P/t Parse Time: several metrics share this display name, not pooled", text)

    def test_metrics_sharing_a_display_name_leave_the_limits_unchanged(self):
        existing = {"P/t": {"Parse Time": 60}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Parse Time", [1, 1], unit="s", identifier="small"),
                            metric("Parse Time", [100, 100], unit="MiB", polarity="prefers larger", identifier="large")]}),
            write_limits=True, existing_limits=existing)
        self.assertEqual(code, 1, text)
        self.assertEqual(json.loads(written), existing)

    def test_metrics_sharing_a_display_name_in_the_base_fail_the_gate(self):
        code, _, text, _ = self.gate(
            bundle({"P/t": [metric("Clock", [1, 1])]}),
            bundle({"P/t": [metric("Clock", [1, 1]), metric("Clock", [1, 1], identifier="other")]}))
        self.assertEqual(code, 1, text)
        self.assertIn("base P/t Clock: several metrics share this display name", text)


    # MARK: polarity against the base

    def test_changed_polarity_against_the_base_fails(self):
        for base_polarity, candidate_polarity, expected in (
                (None, "unspecified", "polarity unspecified against base prefersSmaller"),
                (None, "prefers larger", "polarity prefersLarger against base prefersSmaller"),
                ("prefers larger", None, "polarity prefersSmaller against base prefersLarger")):
            code, _, text, _ = self.gate(
                bundle({"P/t": [metric("Clock", [100, 100], polarity=candidate_polarity)]}),
                bundle({"P/t": [metric("Clock", [1, 1], polarity=base_polarity)]}))
            self.assertEqual(code, 1, text)
            self.assertIn(f"P/t Clock: {expected}", text)

    def test_changed_polarity_against_the_base_leaves_the_limits_unchanged(self):
        existing = {"P/t": {"Clock": 500}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [100, 100], polarity="unspecified")]}),
            base=bundle({"P/t": [metric("Clock", [1, 1])]}),
            write_limits=True, existing_limits=existing, extra=["--max-regression", "20", "--allow-environment-mismatch"])
        self.assertEqual(code, 1, text)
        self.assertIn("polarity unspecified against base prefersSmaller", text)
        self.assertEqual(json.loads(written), existing)


    # MARK: tests that ran more than once

    def native_retry(self):
        """A native bundle: the first run failed before measuring, the retry measured and passed."""
        return self.native("retry-after-failure")

    def native(self, name):
        """The metrics and tests exports of a native fixture in scripts/fixtures/benchmark_report."""
        folder = os.path.join(HERE, "fixtures", "benchmark_report", name)
        exports = {}
        for name in ("metrics", "tests"):
            with open(os.path.join(folder, name + ".json")) as handle:
                exports[name] = json.load(handle)
        return exports

    def test_native_retry_after_a_failure_fails_with_and_without_a_selection(self):
        for extra in ([], ["--only", "RetryProbeTests/testFailsBeforeMeasuringOnce"], ["--only", "RetryProbeTests"]):
            code, _, text, _ = self.run_report(self.native_retry(), extra=extra)
            self.assertEqual(code, 1, text)
            self.assertIn("candidate RetryProbeTests/testFailsBeforeMeasuringOnce: ran 2 times (failed, passed), only one run is allowed", text)

    def test_native_retry_after_a_failure_leaves_the_limits_unchanged(self):
        existing = {"RetryProbeTests/testFailsBeforeMeasuringOnce": {"Clock Monotonic Time": 1.0}}
        code, _, text, written = self.run_report(self.native_retry(), write_limits=True, existing_limits=existing)
        self.assertEqual(code, 1, text)
        self.assertEqual(json.loads(written), existing)

    def test_native_retry_after_a_failure_cannot_be_a_base(self):
        candidate = self.native_retry()
        candidate["tests"] = json.loads(json.dumps(candidate["tests"]).replace('"Repetition"', '"Removed"'))
        code, _, text, _ = self.gate(candidate, self.native_retry(), extra=["--allow-environment-mismatch"])
        self.assertEqual(code, 1, text)
        self.assertIn("base RetryProbeTests/testFailsBeforeMeasuringOnce: ran 2 times", text)
        self.assertNotIn("candidate RetryProbeTests", text)

    def test_repeated_assertion_only_test_fails(self):
        code, _, text, _ = self.run_report(
            bundle({}, results={"P/check": "Passed"}, repetitions={"P/check": ["Passed", "Passed"]}), extra=["--only", "P/check"])
        self.assertEqual(code, 1, text)
        self.assertIn("candidate P/check: ran 2 times (passed, passed)", text)

    def test_retried_unselected_test_still_passes_a_selection(self):
        code, last, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "Q/t": [metric("Clock", [1, 1])]}, repetitions={"Q/t": ["Failed", "Passed"]}),
            limits={"P/t": {"Clock": 10}}, extra=["--only", "P"])
        self.assertEqual(code, 0, text)
        self.assertTrue(last.startswith("OK: 1 metrics"), last)

    def test_one_attempt_and_many_measure_iterations_pass(self):
        code, last, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1, 1, 1, 1])]}, repetitions={"P/t": ["Passed"]}), limits={"P/t": {"Clock": 10}})
        self.assertEqual(code, 0, text)
        self.assertTrue(last.startswith("OK: 1 metrics"), last)


    # MARK: configurations and devices

    def test_native_two_configurations_fail_with_and_without_a_selection(self):
        for extra in ([], ["--only", "ConfigurationProbeTests/testSelected"]):
            code, _, text, _ = self.run_report(self.native("two-configurations"), extra=extra)
            self.assertEqual(code, 1, text)
            self.assertIn("candidate: 2 test plan configurations in one bundle, not pooled: Assertions, Measured", text)

    def test_native_two_configurations_leave_the_limits_unchanged(self):
        existing = {"ConfigurationProbeTests/testSelected": {"Clock Monotonic Time": 1.0}}
        code, _, text, written = self.run_report(
            self.native("two-configurations"), write_limits=True, existing_limits=existing, extra=["--limits", "@written"])
        self.assertEqual(code, 1, text)
        self.assertEqual(json.loads(written), existing)

    def test_native_retry_in_one_of_two_configurations_fails(self):
        for extra in ([], ["--only", "ConfigurationProbeTests/testSelected"]):
            code, _, text, _ = self.run_report(self.native("retry-in-one-of-two-configurations"), extra=extra)
            self.assertEqual(code, 1, text)
            self.assertIn("candidate ConfigurationProbeTests/testSelected: ran 2 times in configuration Assertions (failed, passed)", text)

    def test_native_retry_in_one_of_two_configurations_cannot_be_a_base(self):
        existing = {"P/t": {"Clock": 5}}
        code, _, text, written = self.run_report(
            bundle({"ConfigurationProbeTests/testSelected": [metric("Clock Monotonic Time", [0.01, 0.01],
                                                                    identifier="com.apple.dt.XCTMetric_Clock.time.monotonic")]}),
            base=self.native("retry-in-one-of-two-configurations"), write_limits=True, existing_limits=existing,
            extra=["--max-regression", "20", "--allow-environment-mismatch", "--allow-removed"])
        self.assertEqual(code, 1, text)
        self.assertIn("base: 2 test plan configurations in one bundle", text)
        self.assertIn("base ConfigurationProbeTests/testSelected: ran 2 times in configuration Assertions", text)
        self.assertEqual(json.loads(written), existing)

    def test_assertion_only_selection_with_two_configurations_fails(self):
        two = [{"configurationId": "1", "configurationName": "A"}, {"configurationId": "2", "configurationName": "B"}]
        code, _, text, _ = self.run_report(bundle({}, results={"P/check": "Passed"}, configurations=two), extra=["--only", "P/check"])
        self.assertEqual(code, 1, text)
        self.assertIn("candidate: 2 test plan configurations in one bundle, not pooled: A, B", text)

    def test_two_devices_in_the_tests_tree_fail(self):
        other = dict(DEVICE, deviceId="SIM-2")
        code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}, devices=[DEVICE, other]), limits={"P/t": {"Clock": 10}})
        self.assertEqual(code, 1, text)
        self.assertIn("candidate: 2 devices in one bundle, not pooled", text)


    # MARK: skip list

    def test_skipped_failing_test_is_not_checked_and_is_listed(self):
        code, last, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "P/slow": [metric("Clock", [9, 9])]}, results={"P/t": "Passed", "P/slow": "Failed"}),
            limits={"P/t": {"Clock": 10}, "P/slow": {"Clock": 2}}, skipped={"P/slow": "IOS-1: 20% slower, investigating"})
        self.assertEqual(code, 0, text)
        self.assertIn("SKIPPED: P/slow: IOS-1: 20% slower, investigating", text)
        self.assertNotIn("| P/slow |", text)
        self.assertTrue(last.startswith("OK: 1 metrics"), last)

    def test_limits_of_a_skipped_test_that_did_not_run_are_not_required(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}), limits={"P/t": {"Clock": 10}, "P/slow": {"Clock": 2}},
            skipped={"P/slow": "IOS-1: why"})
        self.assertEqual(code, 0, text)

    def test_skipping_a_class_skips_its_tests(self):
        code, _, text, _ = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])], "Q/a": [metric("Clock", [9, 9])]}, results={"P/t": "Passed", "Q/a": "Failed"}),
            limits={"P/t": {"Clock": 10}, "Q/a": {"Clock": 2}, "Q/b": {"Clock": 2}}, skipped={"Q": "IOS-2: why"})
        self.assertEqual(code, 0, text)
        self.assertIn("SKIPPED: Q: IOS-2: why", text)

    def test_writing_limits_keeps_the_entries_of_a_skipped_test(self):
        existing = {"P/t": {"Clock": 2}, "P/slow": {"Clock": 7}}
        code, _, text, written = self.run_report(
            bundle({"P/t": [metric("Clock", [1, 1])]}), write_limits=True, existing_limits=existing, extra=["--limits", "@written"],
            skipped={"P/slow": "IOS-1: why"})
        self.assertEqual(code, 0, text)
        self.assertEqual(json.loads(written), {"P/t": {"Clock": 3.0}, "P/slow": {"Clock": 7}})

    def test_a_skipped_test_is_left_out_of_the_base_too(self):
        manifest = {"configuration": "Release", "xcode": "26.4.1", "host": "Mac", "cpu": "M3"}
        base = bundle({"P/t": [metric("Clock", [1, 1])], "P/slow": [metric("Clock", [1, 1])]}, repetitions={"P/slow": ["Failed", "Passed"]})
        for skipped, expected in ((None, 1), ({"P/slow": "IOS-1: why"}, 0)):
            code, _, text, _ = self.run_report(
                bundle({"P/t": [metric("Clock", [1, 1])]}), base=base, manifests=(manifest, manifest),
                extra=["--max-regression", "20"], skipped=skipped)
            self.assertEqual(code, expected, text)

    def test_invalid_skip_list_fails(self):
        for skipped in ({"P/slow": ""}, {"P/slow": None}, ["P/slow"], {"P slow": "why"}):
            code, _, text, _ = self.run_report(bundle({"P/t": [metric("Clock", [1, 1])]}), skipped=skipped)
            self.assertEqual(code, 1, (skipped, text))
            self.assertIn("FAILED: skip list:", text)


if __name__ == "__main__":
    unittest.main()
