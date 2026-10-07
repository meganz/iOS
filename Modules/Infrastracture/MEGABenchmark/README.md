# MEGABenchmark

Benchmarks for Swift packages, written with `XCTestCase.measure(metrics:)`.
The numbers land in the `.xcresult` bundle. `scripts/benchmark.sh` runs one package's benchmarks headless on a
simulator. `scripts/benchmark_report.py` then checks the numbers against a limits file.

- [Runner and report rules](Docs/REPORT.md): every option, every check and every result.
- [Decisions and measurements](Docs/DECISIONS.md): why the package works this way, with the numbers.

## What the package gives

| Type | What it does | Needs |
|---|---|---|
| `BenchmarkCase` | Base class. Skips every test unless `MEGA_BENCH=1` is in the test environment. Runs 5 iterations by default. | |
| `PeakFootprintMetric` | Samples memory on its own thread: the footprint every 1 ms, the malloc heap every 5 ms. Reports "Peak Heap Growth", "Peak Footprint" and "Footprint Samples" (see below). | |
| `MainThreadStallMetric` | Reports the longest gap between fires of a 5 ms main run loop timer, and the number of gaps over 100 ms. | The block must turn the main run loop. |
| `FrameHitchMetric` | Counts late display-link frames, a proxy for hitches: frames more than half a frame late, their total lateness, and the frame count. No frame at all is an error. | The block must turn the main run loop the whole time, like a scroll. |
| `runOnMainLoop { }` | Runs async main-actor work inside a `measure` block by turning the main run loop. | |
| `turnMainLoop(for:)`, `turnMainLoop(until:)` | Turn the main run loop for a time, or until a condition holds. | |
| `ScrollBenchmark` (product `MEGABenchmarkUI`) | UI test helpers: `fling`, `waitForFirstCell`, `hitchMetrics(for:)` and `measureOptions`. Only UI test bundles of benchmark host apps use it. | iOS 26 for `hitchMetrics` |

`FrameHitchMetric` sees main-thread delivery delays only. It does not see render-server or GPU hitches.

Apple metrics that work in a simulator unit test: `XCTClockMetric`, `XCTCPUMetric()` (process-wide),
`XCTMemoryMetric`, `XCTStorageMetric` and `XCTOSSignpostMetric`.

### The memory numbers

| Display name | Meaning | Gated |
|---|---|---|
| Peak Heap Growth | Malloc bytes in use, peak minus start. Counts every live heap object, on every run. | Yes |
| Peak Footprint | The highest physical footprint seen. A memory kill compares against this number. | No: it depends on what ran before in the process. |
| Footprint Samples | The number of successful footprint reads. | No |

- The custom metrics report MiB (1,048,576 bytes). Apple's memory metrics report kB.
- On a repeated run in one process, the footprint can stay low while the heap grows.
  [Decisions](Docs/DECISIONS.md#three-memory-numbers-and-why-heap-growth-is-gated) shows the numbers.
- A failed footprint read is dropped and not counted. An interval with no successful read is an error.

## How to write a benchmark

```swift
import MEGABenchmark
import XCTest

final class ParsingBenchmarks: BenchmarkCase {
    func testParseTwoMegabytes() {
        let markdown = BenchmarkDocuments.makeLargeDocument(targetBytes: 2_000_000)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), PeakFootprintMetric()]) {
            XCTAssertGreaterThan(MarkdownParser.parse(markdown).blocks.count, 1_000)
        }
    }
}
```

- Put the benchmarks in their own test target, `<Package>Benchmarks`, with `exclude: ["Limits.json"]`.
- Assert the output inside the block. A fast run that does no work is not a measurement.
- Compute fixture data before the block, so it is not timed.
- Use fewer iterations for a block that takes seconds: `options.iterationCount = 2`.
- A UI benchmark hosts a `UIWindow` and turns the run loop with the helpers. Do not `await` inside the block.

`Modules/UI/MEGAMarkdown/Tests/MEGAMarkdownBenchmarks` is a complete example.

## Add benchmarks to a new package

These four steps set up `Modules/Features/MyAwesomePackage`. CI picks the package up with no other wiring.

1. Add a test target to the package's `Package.swift`. Its name must be the package folder name plus `Benchmarks`.

   ```swift
   dependencies: [
       .package(path: "../../Infrastracture/MEGABenchmark")   // relative to your package
   ],
   targets: [
       .testTarget(
           name: "MyAwesomePackageBenchmarks",
           dependencies: [
               "MyAwesomePackage",
               .product(name: "MEGABenchmark", package: "MEGABenchmark")
           ],
           exclude: ["Limits.json"]
       )
   ]
   ```

   Until step 3 creates `Limits.json`, SwiftPM warns "Invalid Exclude ... File not found". The build still works.
2. Add a `BenchmarkCase` subclass in `Tests/MyAwesomePackageBenchmarks/`, as in "How to write a benchmark".
3. Create the limits on the simulator that CI uses:

   ```sh
   scripts/benchmark.sh Modules/Features/MyAwesomePackage --sim-name "iPhone 17 Pro" --sim-os 26.4 --write-limits
   ```

4. Commit the target, the tests and `Tests/MyAwesomePackageBenchmarks/Limits.json`. That file opts the package in to CI.

You do not edit a test plan, a scheme or a Jenkins file. To add limits for one new test later, run step 3 with
`--only MyAwesomeBenchmarks/testNew`. The limits of the other tests stay as they are.

## How to run

```sh
scripts/benchmark.sh Modules/UI/MEGAMarkdown                 # all benchmarks of the package
scripts/benchmark.sh Modules/UI/MEGAMarkdown --only ParsingBenchmarks
scripts/benchmark.sh Modules/UI/MEGAMarkdown --base EARLIER/result.xcresult --max-regression 20
scripts/benchmark.sh Modules/UI/MEGAMarkdown --write-limits  # recalibrate Limits.json from this run
```

- The script builds Release with testability and runs one test at a time.
  It turns off code coverage and sanitizers, also when a custom scheme turns them on.
- The output goes to `derivedData/benchmarks/<target>-<time stamp>`: the result bundle, the log, `report.md` and more.
- The script fails when a test did not pass, a measurement is missing, or an average is outside its limit.
- Without limits and without `--base`, nothing is checked, and the report says "COLLECTION ONLY".
- `--sim-name NAME --sim-os VERSION` picks that simulator, creates it when needed, and boots it.
- A Swift package test target cannot run on a device. See [Device runs](Docs/DECISIONS.md#device-runs).

## Limits

`Tests/<Package>Benchmarks/Limits.json` maps a test and a metric display name to a limit on the average.
A plain number is a maximum. `{"min": N}` is a minimum, for a metric that prefers larger values.

```json
{
  "ParsingBenchmarks/testParseTwoMegabytes": {
    "Clock Monotonic Time": 1.58,
    "Peak Heap Growth": 154.55
  }
}
```

- `--write-limits` writes 3x the average for time and counts, and 1.5x for memory.
  A metric with no direction gets no limit.
- Limits are loose on purpose. They catch a big regression, not a small one.
- Record limits on the simulator that CI uses: `--sim-name "iPhone 17 Pro" --sim-os 26.4`.
- A missing entry means no check. Tighten a number by hand when it must not move.

## CI

The "Benchmarks" stage of the MR build runs the benchmarks of every package that opts in.

- A package opts in when it has `Tests/<Package>Benchmarks/Limits.json`.
- On an MR, a package runs when the MR changes it, a local package it depends on, or the benchmark tooling.
  On `develop`, every opted-in package runs.
- The stage runs on an iPhone 17 Pro simulator with iOS 26.4, the simulator the limits come from.
  It fails when that iOS version is not installed. It never uses another one.
- A failed benchmark fails the MR build. The stage posts the report to the MR and archives the output.

### Skip a failing benchmark

A regression blocks the MR. To unblock it while you investigate, list the test in
`Tests/<Package>Benchmarks/Skipped.json`, with a reason:

```json
{
  "ParsingBenchmarks/testWholeParseTenMegabytes": "IOS-1234: 20% slower after the cmark update, investigating"
}
```

- A key is `Class/test`, or `Class` for every test of the class. The reason is required.
- The script leaves a skipped test out of the run. The report prints a `SKIPPED` line for it, also in the MR comment.
- The skipped test's limits stay in `Limits.json`. Fix the regression or change the limit, then remove the entry.

## Compare two runs

`--base` shows the earlier average and the change for each metric.
`--max-regression N` fails a metric that got worse by more than N percent.
With `--max-regression`, both runs must come from the same device model, OS, configuration, Xcode version,
Mac model and CPU.

Clock and CPU time change by less than 5% between two runs of the same code.
Peak footprint, the longest stall and late frame time can change by about 30%.
So use the regression check on clock and CPU time, or with a wide margin.

## Known limits

- `XCTMemoryMetric` can report a much lower peak than a sampler sees. `PeakFootprintMetric` adds a sampled peak,
  but a 1 ms sample can still miss a shorter one.
- The sampler thread's CPU counts in a process-wide `XCTCPUMetric`.
- `XCTCPUMetric(limitingToCurrentThread: true)` reports nothing on the simulator. Use `XCTCPUMetric()`.
- `XCTHitchMetric` needs an `XCUIApplication`, so it works only in a UI test. Use `FrameHitchMetric` in a package.
- No metric finds memory leaks. Use `trackForMemoryLeaks` from `MEGATest` and the memory graph.
- XCTest calls the metric hooks on a background queue while the main thread waits.
  A metric must not hop to the main queue synchronously: that deadlocks the run.
