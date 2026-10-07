#!/usr/bin/env python3
"""Reads the XCTest performance metrics of a result bundle, prints a Markdown report, and checks limits.

Usage: benchmark_report.py <result.xcresult> [--limits Limits.json] [--only Class[/test]] [--min-samples N]
                           [--base other.xcresult --max-regression PERCENT [--zero-allowance N]
                            [--allow-missing-base] [--allow-removed] [--allow-environment-mismatch]]
                           [--json out.json] [--write-limits Limits.json] [--skipped Skipped.json]

A bundle is usable when it holds exactly one run (one device and one test plan configuration), one record per
test, at least one measurement, every selected test passed, every measured test has a result, and every metric
has at least --min-samples finite samples. With --only, only the matching tests count, and the selector must
match at least one test. Exit code 1 when the candidate bundle is not usable, when a test or metric named in
the limits (within the selection) has no measurement, or when an average is outside its limit.
A selected test that a test plan ran more than once (a retry or a repetition) fails, also when it passed at last.
A bundle with more than one test plan configuration or device in its tests tree fails, also when only one of them
published measurements.
A runner error in the "System Failures" suite (for example a crash in a class tearDown) fails every selection.
Two metrics of one test with the same display name fail: limits and the base cannot tell them apart.
A plain number in the limits is a maximum. {"min": N} is a minimum, for a metric that prefers larger values.
A limit of the wrong kind for the metric's direction fails.
A --limits path that does not exist is an error, except when it is also the --write-limits path (a new file).

--base compares averages per test and metric against another bundle. With --max-regression the base must be
usable too, must come from the same device model, OS and platform, and from the same build configuration,
Xcode, host and CPU as recorded in the manifest.json next to each bundle (scripts/benchmark.sh writes one;
a missing or incomplete manifest fails). Every directed candidate metric in the selection must have a base
measurement (--allow-missing-base reports NEW instead,
also when --only selects a test the base does not have), and every directed base measurement must still be in
the candidate (--allow-removed reports REMOVED instead). Metrics with no direction (frame and sample counts)
are shown, never gated. A base average of 0 fails when the new average is over --zero-allowance (default 0).
Different units, identifiers or polarities fail. --allow-environment-mismatch turns environment differences into a note.
A metric that prefers larger values is gated on its decrease. When the base average is 0 or negative, a
percent means nothing, so the gate fails when the change for the worse is over --zero-allowance.
A selection whose tests all passed but publish no measurement (assertion-only tests) reports ASSERTIONS ONLY.

--write-limits writes the limits from the selected tests of this run after every check passed: 3x the average
for time and counts (counts at least 2), 1.5x for memory, no limit for undirected metrics. A metric that
prefers larger values gets {"min": average / the same factor}. Tests named in the
existing file within the selection must have run; its old numbers are not applied when it is the same file as
--limits (a recalibration). A different --limits file is enforced in full. Entries outside --only are kept as
they are. The file is replaced atomically; a failed run leaves it unchanged.
Without limits and without a base nothing is checked and the report says COLLECTION ONLY.

--skipped FILE names tests to leave out, each with a reason: {"Class/test": "IOS-1234: why"}. A skipped test is
not a result, not a measurement and not a required limit. Its limits stay in the file when limits are written.
The report prints a SKIPPED line for each entry, so a skip stays visible.
"""
import argparse
import json
import math
import os
import subprocess
import sys
import tempfile

MEMORY_UNITS = {"MiB", "MB", "kB"}
# xcresulttool writes "prefers larger" and "unspecified", and leaves the key out for prefers smaller.
POLARITIES = {"prefers larger": "prefersLarger", "preferslarger": "prefersLarger", "prefers smaller": "prefersSmaller",
              "preferssmaller": "prefersSmaller", "unspecified": "unspecified"}


def polarity_of(metric):
    raw = str(metric.get("polarity", "prefers smaller")).strip().lower()
    return POLARITIES.get(raw, "prefersSmaller")
ENVIRONMENT_KEYS = ("configuration", "xcode", "host", "cpu")
DEVICE_KEYS = ("modelName", "osVersion", "platform")


def xcresulttool(subcommand, xcresult):
    output = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", subcommand, "--path", xcresult, "--compact"],
        capture_output=True, text=True, check=True).stdout
    return json.loads(output)


def strip_parentheses(identifier):
    return identifier.replace("()", "")


def find_tests(data):
    """The root of the metrics JSON holds one list of tests. The key name is not part of the documented schema."""
    if isinstance(data, list):
        return data
    for value in data.values():
        if isinstance(value, list) and all(isinstance(item, dict) and "testIdentifier" in item for item in value):
            return value
    return []


def load_bundle(xcresult):
    """Everything the checks need from one result bundle.

    runs: {(device id, configuration): {test: {metric: {"unit", "identifier", "polarity", "values"}}}}
    records: {(device id, configuration): {test: number of run records}}
    devices: [{"modelName", "osVersion", "platform", "deviceName"}] from the tests tree
    results: {test: "Passed" | "Failed" | "Skipped" | ...}
    system_failures: [name of each runner error in the "System Failures" suite]
    repetitions: {test: [(configuration name or None, [result of each attempt])]} for a test run more than once
    configurations: names of the test plan configurations that ran, from the tests tree
    manifest: the runner's manifest.json next to the bundle, or {}
    """
    runs = {}
    records = {}
    for test in find_tests(xcresulttool("metrics", xcresult)):
        name = strip_parentheses(test["testIdentifier"])
        for run in test.get("testRuns", []):
            key = (run.get("device", {}).get("deviceId", "unknown device"),
                   run.get("testPlanConfiguration", {}).get("configurationName", "unknown configuration"))
            per_test = runs.setdefault(key, {})
            per_test.setdefault(name, {})
            counts = records.setdefault(key, {})
            counts[name] = counts.get(name, 0) + 1
            display_names = set()
            for metric in run.get("metrics", []):
                display_name = metric["displayName"]
                entry = per_test[name].setdefault(display_name, {
                    "unit": metric.get("unitOfMeasurement", ""),
                    "identifier": metric.get("identifier", ""),
                    "polarity": polarity_of(metric),
                    "values": [],
                })
                if display_name in display_names:
                    # Limits and the base are keyed by display name, so two metrics with one name cannot be told apart.
                    entry["shared_name"] = True
                display_names.add(display_name)
                entry["values"].extend(metric.get("measurements", []))
    tests = xcresulttool("tests", xcresult)
    results = {}
    system_failures = []
    repetitions = {}

    def collect_attempts(node, configuration, attempts):
        for child in node.get("children", []):
            if child.get("nodeType") == "Repetition":
                attempts.setdefault(configuration, []).append(child.get("result", ""))
            elif child.get("nodeType") == "Test Plan Configuration":
                collect_attempts(child, child.get("name", ""), attempts)

    def walk(node, in_system_failures=False):
        # Xcode reports runner errors (for example a crash in a class tearDown) as test cases of this suite.
        if node.get("nodeType") == "Test Suite" and node.get("name") == "System Failures":
            in_system_failures = True
        if node.get("nodeType") == "Test Case" and "nodeIdentifier" in node:
            if in_system_failures:
                system_failures.append(node.get("name") or node["nodeIdentifier"])
            else:
                test = strip_parentheses(node["nodeIdentifier"])
                results[test] = node.get("result", "")
                # A test plan can retry or repeat a test. The test's own result then shows only the last attempt.
                # With several configurations, the attempts sit under a "Test Plan Configuration" node.
                attempts = {}
                collect_attempts(node, None, attempts)
                repeated = [(configuration, results) for configuration, results in sorted(attempts.items(), key=str) if len(results) > 1]
                if repeated:
                    repetitions[test] = repeated
        for child in node.get("children", []):
            walk(child, in_system_failures)

    for node in tests.get("testNodes", []):
        walk(node)
    manifest = {}
    manifest_path = os.path.join(os.path.dirname(os.path.abspath(xcresult)), "manifest.json")
    if os.path.isfile(manifest_path):
        with open(manifest_path) as handle:
            manifest = json.load(handle)
    return {"path": xcresult, "runs": runs, "records": records, "devices": tests.get("devices", []),
            "results": results, "system_failures": system_failures, "repetitions": repetitions,
            "configurations": [entry.get("configurationName", "") for entry in tests.get("testPlanConfigurations", [])],
            "manifest": manifest}


def average(values):
    return sum(values) / len(values) if values else 0.0


def is_selected(test, only):
    """`--only Class` selects every test of the class, `--only Class/test` one test."""
    if not only:
        return True
    only = only.rstrip("/")
    return test == only or test.startswith(only + "/")


def is_finite_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def repetition_failures(bundle, label, only):
    """A selected test that ran more than once fails, also when its last attempt passed: only one run is allowed."""
    failures = []
    for test, repeated in sorted(bundle["repetitions"].items()):
        if not is_selected(test, only):
            continue
        for configuration, attempts in repeated:
            where = f" in configuration {configuration}" if configuration is not None else ""
            listed = ", ".join(result.lower() or "no result" for result in attempts)
            failures.append(f"{label} {test}: ran {len(attempts)} times{where} ({listed}), only one run is allowed")
    return failures


def usable_metrics(bundle, label, only, min_samples, selection_may_be_empty=False):
    """Returns (metrics of the selected tests of the single run, failures).
    A bundle with any failure must not drive a decision. `selection_may_be_empty` is for a valid base that
    simply has no test matching --only (a new test): the base is still checked for being one usable run."""
    # A runner error is not a test, so --only never filters it out.
    failures = [f"{label}: runner error: {name}" for name in bundle["system_failures"]]
    # The tests tree lists every configuration and device that ran, also those that published no measurement.
    if len(bundle["configurations"]) > 1:
        failures.append(f"{label}: {len(bundle['configurations'])} test plan configurations in one bundle, not pooled: "
                        f"{', '.join(sorted(bundle['configurations']))}")
    if len(bundle["devices"]) > 1:
        failures.append(f"{label}: {len(bundle['devices'])} devices in one bundle, not pooled")
    runs = bundle["runs"]
    results = bundle["results"]
    if not runs:
        # A run of assertion-only tests has an empty metrics array. Its selected tests must still have passed.
        selected = [test for test in results if is_selected(test, only)]
        if only and selected:
            failures += [f"{label} {test}: {results[test].lower() or 'no result'}" for test in sorted(selected) if results[test] != "Passed"]
            failures += repetition_failures(bundle, label, only)
            return {}, failures
        failures.append(f"{label}: no performance metrics in the result bundle")
        return {}, failures
    if len(runs) > 1:
        described = ", ".join(f"{device} / {configuration}" for device, configuration in sorted(runs))
        failures.append(f"{label}: {len(runs)} runs in one bundle, not pooled: {described}")
        return {}, failures
    key = next(iter(runs))
    metrics = {test: by_metric for test, by_metric in runs[key].items() if is_selected(test, only)}
    if only and not metrics and not any(is_selected(test, only) for test in bundle["results"]):
        if selection_may_be_empty:
            # Nothing to compare, but the whole bundle must still be a usable run.
            # The whole-bundle check reports the runner errors again, so only its failures are returned.
            _, whole_failures = usable_metrics(bundle, label, None, min_samples)
            return {}, whole_failures
        failures.append(f"{label}: no test matches --only {only}")
        return {}, failures
    # A selection of assertion-only tests measures nothing (xcresulttool lists no run for them at all);
    # the result checks below still apply to it.
    if not any(metrics.values()) and not (only and any(is_selected(test, only) for test in results)):
        failures.append(f"{label}: no performance metrics in the result bundle")
        return {}, failures
    for test, count in sorted(bundle["records"][key].items()):
        if is_selected(test, only) and count > 1:
            failures.append(f"{label} {test}: {count} run records for one test, not pooled")
    for test, result in sorted(results.items()):
        if is_selected(test, only) and result != "Passed":
            failures.append(f"{label} {test}: {result.lower() or 'no result'}")
    failures += repetition_failures(bundle, label, only)
    for test, by_metric in sorted(metrics.items()):
        if test not in results:
            failures.append(f"{label} {test}: measured, but no test result")
        for metric, entry in sorted(by_metric.items()):
            values = entry["values"]
            if entry.get("shared_name"):
                failures.append(f"{label} {test} {metric}: several metrics share this display name, not pooled")
            elif any(not is_finite_number(value) for value in values):
                failures.append(f"{label} {test} {metric}: a sample is not a finite number")
            elif len(values) < min_samples:
                failures.append(f"{label} {test} {metric}: {len(values)} samples, at least {min_samples} needed")
    return metrics, failures


def parse_limit(limit):
    """A plain number is a maximum, {"min": N} is a minimum. Returns ("max" | "min", N), or None when invalid."""
    if is_finite_number(limit):
        return "max", limit
    if isinstance(limit, dict) and list(limit) == ["min"] and is_finite_number(limit["min"]):
        return "min", limit["min"]
    return None


def coverage_failures(metrics, results, limits, only):
    """Every test and metric named in the limits, within the selection, must have run and been measured."""
    failures = []
    for test, metric_limits in sorted(limits.items()):
        if not is_selected(test, only):
            continue
        if test not in results:
            failures.append(f"{test}: did not run")
            continue
        for metric, limit in sorted(metric_limits.items()):
            if parse_limit(limit) is None:
                failures.append(f"{test} {metric}: the limit {limit!r} is not a finite number or {{\"min\": number}}")
            if metric not in metrics.get(test, {}):
                failures.append(f"{test} {metric}: no measurement")
    return failures


def environment_differences(candidate, base):
    """Device model, OS and platform from the bundles; configuration, Xcode, host and CPU from the manifests.
    An unknown value never counts as equal."""
    differences = []

    def device_summary(bundle):
        return sorted({tuple(device.get(key) for key in DEVICE_KEYS) for device in bundle["devices"]})

    for label, bundle in (("candidate", candidate), ("base", base)):
        if not bundle["devices"] or any(not device.get(key) for device in bundle["devices"] for key in DEVICE_KEYS):
            differences.append(f"{label}: device model, OS or platform unknown in the result bundle")
        for key in ENVIRONMENT_KEYS:
            if not bundle["manifest"].get(key):
                differences.append(f"{label}: {key} unknown (no manifest.json next to the bundle, or no value)")
    if differences:
        return differences
    if device_summary(candidate) != device_summary(base):
        differences.append(f"device {device_summary(candidate)} against base {device_summary(base)}")
    for key in ENVIRONMENT_KEYS:
        if candidate["manifest"][key] != base["manifest"][key]:
            differences.append(f"{key} {candidate['manifest'][key]!r} against base {base['manifest'][key]!r}")
    return differences


def compare(test, metric, entry, base_entry, args):
    """Returns (base average text, change text, failure or None, status or None).
    Worse means larger for a metric that prefers smaller values, smaller for one that prefers larger values."""
    gated = args.max_regression is not None and entry["polarity"] != "unspecified"
    if base_entry is None or not base_entry["values"]:
        if gated and not args.allow_missing_base:
            return "", "", f"{test} {metric}: no base measurement", None
        return "", "new", None, "NEW" if gated else None
    if base_entry["unit"] != entry["unit"]:
        return "", "", f"{test} {metric}: unit {entry['unit']} against base unit {base_entry['unit']}", None
    if base_entry["identifier"] != entry["identifier"]:
        return "", "", f"{test} {metric}: identifier {entry['identifier']} against base {base_entry['identifier']}", None
    if base_entry["polarity"] != entry["polarity"]:
        # The candidate's direction decides the gate, so a changed direction could turn the gate off or around.
        return "", "", f"{test} {metric}: polarity {entry['polarity']} against base {base_entry['polarity']}", None
    base_average = average(base_entry["values"])
    current = average(entry["values"])
    worse_by = (base_average - current) if entry["polarity"] == "prefersLarger" else (current - base_average)
    if base_average <= 0:
        change = f"{current - base_average:+.2f}"
        failure = None
        if gated and worse_by > args.zero_allowance:
            failure = f"{test} {metric}: {current:.2f} against a base of {base_average:.2f}, worse by {worse_by:.2f}"
        return f"{base_average:.2f}", change, failure, None
    percent = (current - base_average) / base_average * 100
    worse_percent = worse_by / base_average * 100
    failure = f"{test} {metric}: {percent:+.1f}% against the base" if gated and worse_percent > args.max_regression else None
    return f"{base_average:.2f}", f"{percent:+.1f}%", failure, None


def removed_from_candidate(metrics, base_metrics, allow_removed):
    """Directed base measurements that the candidate no longer has: failures, or REMOVED rows when allowed."""
    failures = []
    rows = []
    for test, by_metric in sorted(base_metrics.items()):
        for metric, entry in sorted(by_metric.items()):
            if entry["polarity"] == "unspecified" or metric in metrics.get(test, {}):
                continue
            if allow_removed:
                rows.append([test, metric, "", "", "", entry["unit"], f"{average(entry['values']):.2f}", "removed", "", "REMOVED"])
            else:
                failures.append(f"{test} {metric}: in the base, not in the candidate")
    return failures, rows


def limits_from(metrics, results):
    """3x the average for time and counts (counts at least 2), 1.5x for memory, rounded up to 2 decimals.
    A metric that prefers larger values gets a minimum: the average divided by the same factor, rounded down."""
    limits = {}
    for test, by_metric in metrics.items():
        if results.get(test) != "Passed":
            continue
        for metric, entry in by_metric.items():
            if entry.get("polarity") == "unspecified" or not entry["values"]:
                continue
            factor = 1.5 if entry["unit"] in MEMORY_UNITS else 3
            if entry.get("polarity") == "prefersLarger":
                mean = average(entry["values"])
                # Dividing a negative average would raise the minimum above it, so it is multiplied instead.
                minimum = math.floor((mean / factor if mean >= 0 else mean * factor) * 100) / 100
                if entry["unit"] == "count":
                    minimum = math.floor(minimum)
                limits.setdefault(test, {})[metric] = {"min": minimum}
                continue
            limit = math.ceil(average(entry["values"]) * factor * 100) / 100
            if entry["unit"] == "count":
                # A count that is 0 on average must not fail on one stall or hitch in one iteration.
                limit = max(math.ceil(limit), 2)
            limits.setdefault(test, {})[metric] = max(limit, 0.01)
    return limits


def write_limits(path, limits):
    """Writes the whole file at once: a temporary file in the same folder, then a rename."""
    folder = os.path.dirname(os.path.abspath(path)) or "."
    handle, temporary = tempfile.mkstemp(prefix=".limits-", suffix=".json", dir=folder)
    try:
        with os.fdopen(handle, "w") as output:
            json.dump(limits, output, indent=2, sort_keys=True)
            output.write("\n")
        os.replace(temporary, path)
    except BaseException:
        if os.path.exists(temporary):
            os.remove(temporary)
        raise


def read_limits(path):
    with open(path) as handle:
        limits = json.load(handle)
    if not isinstance(limits, dict) or not all(isinstance(value, dict) for value in limits.values()):
        raise ValueError(f"{path}: expected {{test: {{metric: limit}}}}")
    return limits


def read_skipped(path):
    """{"Class/test" or "Class": "reason"}. A reason is required, so a skip always says why and where it is tracked."""
    with open(path) as handle:
        skipped = json.load(handle)
    if not isinstance(skipped, dict):
        raise ValueError(f"{path}: expected {{\"Class/test\": \"reason\"}}")
    for test, reason in skipped.items():
        if not test.strip("/") or " " in test:
            raise ValueError(f"{path}: {test!r} is not a Class or Class/test name")
        if not isinstance(reason, str) or not reason.strip():
            raise ValueError(f"{path}: {test} needs a reason")
    return skipped


def is_skipped(test, skipped):
    return any(is_selected(test, entry) for entry in skipped)


def drop_skipped(bundle, skipped):
    """A skipped test counts nowhere: not as a result, not as a measurement, not as a repetition."""
    for per_test in bundle["runs"].values():
        for test in [test for test in per_test if is_skipped(test, skipped)]:
            del per_test[test]
    for counts in bundle["records"].values():
        for test in [test for test in counts if is_skipped(test, skipped)]:
            del counts[test]
    for key in ("results", "repetitions"):
        bundle[key] = {test: value for test, value in bundle[key].items() if not is_skipped(test, skipped)}
    bundle["runs"] = {key: per_test for key, per_test in bundle["runs"].items() if per_test}

OK_STATUSES = ("ok", "NEW", "REMOVED")


def print_table(header, rows):
    print("| " + " | ".join(header) + " |")
    print("|" + "---|" * len(header))
    for row in rows:
        print("| " + " | ".join(row) + " |")
    print()


def print_groups(header, rows):
    """One group per test class. Failed rows stay open. Passed rows are folded, as a reference."""
    suites = {}
    for row in rows:
        suites.setdefault(row[0].split("/")[0], []).append(row)
    for suite, suite_rows in suites.items():
        failed = [row for row in suite_rows if row[-1] not in OK_STATUSES]
        passed = [row for row in suite_rows if row[-1] in OK_STATUSES]
        print(f"**{suite}** {'FAILED' if failed else 'passed'}\n")
        if failed:
            print_table(header, failed)
        if passed:
            print(f"<details>\n<summary>Passed ({len(passed)})</summary>\n")
            print_table(header, passed)
            print("</details>\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("xcresult")
    parser.add_argument("--limits")
    parser.add_argument("--only", help="the Class or Class/test the run was limited to")
    parser.add_argument("--min-samples", type=int, default=2, help="samples each metric must have (default 2)")
    parser.add_argument("--base")
    parser.add_argument("--max-regression", type=float, help="percent growth of an average allowed against --base")
    parser.add_argument("--zero-allowance", type=float, default=0, help="allowed average when the base average is 0")
    parser.add_argument("--allow-missing-base", action="store_true", help="a metric without a base measurement is NEW, not a failure")
    parser.add_argument("--allow-removed", action="store_true", help="a base metric missing from the candidate is REMOVED, not a failure")
    parser.add_argument("--allow-environment-mismatch", action="store_true", help="report environment differences, do not fail")
    parser.add_argument("--json", help="write the flat metrics to this file")
    parser.add_argument("--write-limits", help="write a limits file from this run after every check passed")
    parser.add_argument("--skipped", help="a skip list: these tests are not checked, and the report lists them")
    args = parser.parse_args()
    if args.max_regression is not None and not args.base:
        parser.error("--max-regression needs --base")
    if args.max_regression is not None and not is_finite_number(args.max_regression):
        parser.error("--max-regression must be a finite number")
    if not is_finite_number(args.zero_allowance):
        parser.error("--zero-allowance must be a finite number")
    if args.min_samples < 1:
        parser.error("--min-samples must be at least 1")

    if not os.path.isdir(args.xcresult):
        print(f"FAILED: no result bundle at {args.xcresult} (the build or the test run failed)")
        sys.exit(1)
    writing = bool(args.write_limits)
    same_file = writing and args.limits and os.path.abspath(args.limits) == os.path.abspath(args.write_limits)
    limits = {}
    if args.limits and not same_file:
        if not os.path.isfile(args.limits):
            print(f"FAILED: no limits file at {args.limits}")
            sys.exit(1)
        limits = read_limits(args.limits)
    existing_limits = {}
    if writing and os.path.isfile(args.write_limits):
        existing_limits = read_limits(args.write_limits)
    skipped = {}
    if args.skipped:
        try:
            skipped = read_skipped(args.skipped)
        except (OSError, ValueError) as error:
            print(f"FAILED: skip list: {error}")
            sys.exit(1)

    candidate = load_bundle(args.xcresult)
    drop_skipped(candidate, skipped)
    metrics, failures = usable_metrics(candidate, "candidate", args.only, args.min_samples)
    if args.json:
        with open(args.json, "w") as handle:
            json.dump(metrics, handle, indent=1, sort_keys=True)
    # Recalibration keeps the coverage of the old file, not its numbers. A separate --limits file is enforced in full.
    required = {test: entry for test, entry in limits.items() if not is_skipped(test, skipped)}
    failures += coverage_failures(metrics, candidate["results"], required, args.only)
    if writing:
        required = {test: entry for test, entry in existing_limits.items() if not is_skipped(test, skipped)}
        failures += coverage_failures(metrics, candidate["results"], required, args.only)

    base_metrics = {}
    notes = []
    removed_rows = []
    if args.base:
        if not os.path.isdir(args.base):
            failures.append(f"base: no result bundle at {args.base}")
        else:
            base = load_bundle(args.base)
            drop_skipped(base, skipped)
            base_metrics, base_failures = usable_metrics(
                base, "base", args.only, args.min_samples, selection_may_be_empty=bool(args.only) and args.allow_missing_base)
            if args.max_regression is not None:
                failures += base_failures
                differences = environment_differences(candidate, base)
                if args.allow_environment_mismatch:
                    notes += [f"environment: {difference}" for difference in differences]
                else:
                    failures += [f"environment: {difference}" for difference in differences]
                removed_failures, removed_rows = removed_from_candidate(metrics, base_metrics, args.allow_removed)
                failures += removed_failures

    header = ["Test", "Metric", "Avg", "Min", "Max", "Unit", "Limit", "Status"]
    if args.base:
        header[6:6] = ["Base avg", "Change"]
    rows = []
    for test in sorted(metrics):
        for metric in sorted(metrics[test]):
            entry = metrics[test][metric]
            values = entry["values"] or [0]
            avg = average(values)
            limit = limits.get(test, {}).get(metric)
            status = "ok"
            if limit is not None and entry["polarity"] == "unspecified":
                # A metric with no direction is a diagnostic. Its limit is a policy mistake, not a failure.
                notes.append(f"{test} {metric}: the limit {limit} is ignored, this metric has no direction")
                limit = None
            bound = parse_limit(limit) if limit is not None else None
            larger_is_better = entry["polarity"] == "prefersLarger"
            if bound and bound[0] == "max" and larger_is_better:
                # A maximum on such a metric would pass a drop and fail a gain.
                status = "WRONG LIMIT"
                failures.append(f"{test} {metric}: a plain limit is a maximum, but this metric prefers larger values. "
                                f"Write {{\"min\": number}}")
            elif bound and bound[0] == "min" and not larger_is_better:
                status = "WRONG LIMIT"
                failures.append(f"{test} {metric}: a minimum limit, but this metric prefers smaller values. Write a plain number")
            elif bound and bound[0] == "max" and avg > bound[1]:
                status = "OVER LIMIT"
                failures.append(f"{test} {metric}: average {avg:.2f} over limit {bound[1]}")
            elif bound and bound[0] == "min" and avg < bound[1]:
                status = "UNDER LIMIT"
                failures.append(f"{test} {metric}: average {avg:.2f} under the minimum {bound[1]}")
            row = [test, metric, f"{avg:.2f}", f"{min(values):.2f}", f"{max(values):.2f}", entry["unit"]]
            if args.base:
                base_text, change, failure, new_status = compare(
                    test, metric, entry, base_metrics.get(test, {}).get(metric), args)
                row += [base_text, change]
                if failure:
                    status = "REGRESSION"
                    failures.append(failure)
                elif new_status:
                    status = new_status
            limit_text = "" if limit is None else f"min {bound[1]}" if bound and bound[0] == "min" else str(limit)
            row += [limit_text, status]
            rows.append(row)
    rows += removed_rows

    print_groups(header, rows)
    for note in notes:
        print(f"NOTE: {note}")
    for test, reason in sorted(skipped.items()):
        print(f"SKIPPED: {test}: {reason}")
    if failures:
        print("FAILED:")
        for failure in failures:
            print(f"- {failure}")
        if writing:
            print(f"Limits file not written: {args.write_limits}")
        sys.exit(1)
    if writing:
        new_limits = limits_from(metrics, candidate["results"])
        # A skipped test did not run, so its old limits stay for the day it runs again.
        kept = {test: entry for test, entry in existing_limits.items()
                if not is_selected(test, args.only) or is_skipped(test, skipped)}
        write_limits(args.write_limits, {**kept, **new_limits})
        print(f"OK: {len(rows)} metrics recorded, limits written to {args.write_limits}")
        return
    if not rows:
        passed = sum(1 for test, result in candidate["results"].items() if is_selected(test, args.only) and result == "Passed")
        print(f"ASSERTIONS ONLY: {passed} selected tests passed, none publishes a measurement, so no number was checked")
        return
    if not limits and not args.base:
        print(f"COLLECTION ONLY: {len(rows)} metrics recorded, no limits file and no base, so nothing was checked")
        return
    print(f"OK: {len(rows)} metrics within limits")


if __name__ == "__main__":
    main()
