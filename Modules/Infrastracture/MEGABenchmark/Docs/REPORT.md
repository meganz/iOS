# Runner and report rules

This page lists what `scripts/benchmark.sh` runs and how `scripts/benchmark_report.py` decides.
The package [README](../README.md) shows the everyday commands.

## The runner

`scripts/benchmark.sh <package dir> [options]` runs one benchmark target of a package on an iOS simulator.

| Option | Meaning |
|---|---|
| `--scheme S` | xcodebuild scheme. Default: the package's `-Package` scheme, or the package name. |
| `--target T` | Benchmark test target. Default: `<package name>Benchmarks`. |
| `--only Class[/test]` | Runs one class or one test of the target. |
| `--sim UDID` | Simulator. Default: the first booted iPhone. |
| `--sim-name NAME --sim-os VERSION` | The simulator with this name and iOS version. See "The simulator" below. |
| `--limits FILE` | Limits file. Default: `<package>/Tests/<target>/Limits.json` when it exists. |
| `--skipped FILE` | Skip list. Default: `<package>/Tests/<target>/Skipped.json` when it exists. |
| `--base XCRESULT` | An earlier result bundle to compare against. |
| `--max-regression PERCENT` | With `--base`: fails a metric that got worse by more than this. |
| `--write-limits` | Writes the limits file from this run. |
| `--debug` | Debug build. Default: Release with `ENABLE_TESTABILITY=YES`. |
| `--out DIR` | Output folder. Default: `derivedData/benchmarks/<target>-<time stamp>`. |

The runner always:
- sets `TEST_RUNNER_MEGA_BENCH=1`, so `BenchmarkCase` tests run;
- passes the configuration explicitly, so the scheme's own test configuration cannot differ from the manifest;
- turns off parallel testing, code coverage, and the address, thread and undefined behavior sanitizers;
- writes `manifest.json` with the configuration, Xcode version, Mac model, CPU, simulator and commit.

A scheme's test plan can still retry or repeat a test. The report rejects such a run (see below).

### The simulator

`--sim-name` and `--sim-os` go together, and not with `--sim`. `scripts/benchmark_ci.py simulator` picks the
simulator:

- The iOS runtime must be `VERSION` or a patch of it: `26.4` accepts 26.4 and 26.4.1. `VERSION` needs at least
  major.minor.
- It takes an available simulator with that exact name. When there is none, it creates one with that runtime.
- When no such runtime is installed, it fails and lists the installed iOS versions. It never picks another OS.

The runner then boots the simulator and waits until it is ready.

### The skip list

A skip list is a JSON object: `{"Class/test": "reason"}`. A key `Class` skips every test of the class.

- Every reason must be a non-empty string. A list that breaks this stops the runner before the build.
- The runner passes `-skip-testing:<target>/<key>` for each entry, so a skipped test does not run.
- The report gets the list with `--skipped`. A skipped test is not a result, a measurement or a required limit,
  in the candidate and in the base.
- The report prints `SKIPPED: <key>: <reason>` for each entry.
- `--write-limits` keeps the limits of a skipped test as they are.

The output folder holds `result.xcresult`, `xcodebuild.log`, `manifest.json`, `metrics.json` and `report.md`.
The runner fails when `xcodebuild` fails or when the report fails.
It never passes `--write-limits` to the report after a failed `xcodebuild`.

## A usable bundle

The report reads the bundle with `xcrun xcresulttool get test-results metrics` and `tests`.
A bundle is usable only when all of these hold:

- The tests tree has one test plan configuration and one device.
- The metrics have one run: one device and one configuration. Runs are never pooled.
- Each test has one run record.
- No selected test ran more than once. A retry shows as several `Repetition` nodes, also under a
  `Test Plan Configuration` node. The test's own result shows only the last attempt.
- No runner error is in Xcode's "System Failures" suite, for example a crash in a class `tearDown`.
  `--only` never filters out a runner error.
- Every selected test passed, and every measured test has a test result.
- Every metric has at least `--min-samples` finite samples (default 2).
- No two metrics of one test share a display name. Limits and the base are keyed by that name.

`--only Class` selects every test of the class. `--only Class/test` selects one test.
The selector must match at least one test.

## Limits

A limits file maps a test and a metric display name to a limit on the average:

| Value | Meaning | For a metric that prefers |
|---|---|---|
| A number | Maximum. The run fails when the average is over it. | smaller values |
| `{"min": N}` | Minimum. The run fails when the average is under it. | larger values |

- A limit of the wrong kind for the metric's direction fails.
- A limit on a metric with no direction is ignored, with a note.
- Every test and metric named in the file, within the selection, must have run and been measured.
- A limit that is not a finite number, or not `{"min": number}`, fails.
- A `--limits` path that does not exist fails, except when it is also the `--write-limits` path.

## Writing limits

`--write-limits FILE` writes the file only after every other check passed. It writes from the selected tests.

| Metric | Written limit |
|---|---|
| Time, CPU and counts, smaller is better | 3x the average, rounded up to 2 decimals. A count limit is at least 2. |
| Memory (MiB, MB, kB), smaller is better | 1.5x the average |
| Larger is better | `{"min": N}`: the average divided by the same factor, rounded down. A negative average is multiplied instead. |
| No direction | No limit |

- Tests named in the old file within the selection must have run.
- When `FILE` is also the `--limits` file, its old numbers are not applied. This is a recalibration.
- A different `--limits` file is enforced in full.
- With `--only`, the entries of other tests are kept as they are.
- The file is replaced in one step. A failed run leaves it unchanged.

## Comparing with a base

`--base OTHER.xcresult` adds the base average and the change to each row.
A metric whose unit, identifier or direction differs from the base fails.
With `--max-regression PERCENT` the comparison also gates:

- The base must be a usable bundle too.
- Device model, OS and platform must match, from the bundles.
- Configuration, Xcode, Mac model and CPU must match, from the `manifest.json` next to each bundle.
  A missing value never matches. `--allow-environment-mismatch` turns a difference into a note.
- Every directed candidate metric needs a base measurement. `--allow-missing-base` reports NEW instead.
- Every directed base measurement must still be in the candidate. `--allow-removed` reports REMOVED instead.
- Worse means larger for a metric that prefers smaller values, and smaller for one that prefers larger values.
- When the base average is 0 or less, a percent means nothing. The gate then fails when the change for the worse
  is over `--zero-allowance` (default 0).
- Metrics with no direction are shown, never gated.

## Results

| Last line | Meaning |
|---|---|
| `OK: N metrics within limits` | Every check passed. |
| `OK: N metrics recorded, limits written to FILE` | Every check passed, and the limits file was written. |
| `COLLECTION ONLY` | No limits and no base, so nothing was checked. |
| `ASSERTIONS ONLY` | The selected tests passed and none publishes a measurement. |
| `FAILED:` and a list | At least one check failed. The exit code is 1. |

A row's status is `ok`, `OVER LIMIT`, `UNDER LIMIT`, `WRONG LIMIT`, `REGRESSION`, `NEW` or `REMOVED`.
`--json FILE` writes the measurements of the selected tests.

## The CI stage

`jenkinsfile/benchmarks.groovy` holds the "Benchmarks" stage of `jenkinsfile/ios_build_status.groovy`.

1. `scripts/benchmark_ci.py packages` lists the packages to run. A package opts in with
   `Tests/<package folder name>Benchmarks/Limits.json`.
   - On `develop`, or without an MR, it lists every opted-in package.
   - On an MR, it lists a package when the diff against `origin/develop` changes a file in the package, or in a
     local package it depends on through `.package(path:)`, recursively. A changed submodule that holds such a
     package counts too.
   - A change to the benchmark tooling lists every opted-in package. The tooling is `scripts/benchmark.sh`,
     `scripts/benchmark_report.py`, `scripts/benchmark_ci.py`, `scripts/fixtures/benchmark_report/`,
     `jenkinsfile/benchmarks.groovy` and `fastlane/Fastfile_post_benchmarks`.
   - When the selection fails, every opted-in package runs.
2. With no package listed, the stage ends at once. Otherwise it sets up the workspace like the other stages.
3. For each package it runs `scripts/benchmark.sh <package> --sim-name "iPhone 17 Pro" --sim-os 26.4`.
   It runs every package, also after a failure.
4. It joins the reports into `outputs/benchmarks.md`. The stage fails when any package failed.
5. After the stage, also after a failure, it archives `report.md`, `metrics.json`, `manifest.json`,
   `xcodebuild.log` and the zipped result bundle of each package. It posts `outputs/benchmarks.md` to the MR with
   the `post_benchmark_report_to_mr` fastlane lane.

## Tests of the scripts

- `scripts/benchmark_report_test.py` feeds raw xcresulttool JSON through the real loader for each rule.
- `scripts/fixtures/benchmark_report/` holds native xcresulttool exports. Each has a README that says how it was made.
- `scripts/benchmark_runner_test.py` runs `scripts/benchmark.sh` with fake `xcodebuild`, `xcrun` and reporter commands.
  It checks the forwarded arguments, the manifest, the simulator options, the skip list, and that a failed build
  never asks for a limits write.
- `scripts/benchmark_ci_test.py` checks the package selection on a small repo tree, the simulator choice, and the
  skip list check.
