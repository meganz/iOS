# Decisions and measurements

Why the package works the way it does, with the numbers behind it.
The numbers come from Xcode 26.4.1 on iPhone 17 and iPhone 17 Pro simulators with iOS 26.4.
The workload was the MEGAMarkdown parser. A number from one workload is an observation, not a rule.

## What XCTest gives, and what is custom

| Need | XCTest API | Status | Notes |
|---|---|---|---|
| Clock time | `XCTClockMetric` | Supported, used | The same numbers as `ContinuousClock`. |
| CPU | `XCTCPUMetric()` | Supported, used | CPU time, instructions retired and cycles. `limitingToCurrentThread: true` reported nothing on the simulator. |
| Memory peak | `XCTMemoryMetric` | Supported, not used for gating | On one 10 MB parse it reported a 41 MB peak where a 1 ms sampler saw 366 MB. On a 200 MB buffer held for 20 ms it reported 240 MB. |
| Memory retained | `XCTMemoryMetric` "Memory Physical" | Supported | The change before and after the block, in kB. Noisy at kB level. |
| Memory leak | none | Not available | Growth over the iterations is a signal, not proof: caches and the allocator also grow. Use `trackForMemoryLeaks` from `MEGATest` and the memory graph. |
| Disk | `XCTStorageMetric` | Supported | Logical disk writes in kB. |
| Hitch | `XCTHitchMetric` | UI tests only | It needs `init(application:)`. An animation signpost with `XCTOSSignpostMetric` gave only a duration in a unit test. `FrameHitchMetric` is a proxy. |
| Main thread stall | none | Custom | `MainThreadStallMetric`. |
| App launch | `XCTApplicationLaunchMetric` | UI tests only | Not needed for packages. |
| Headless run | `xcodebuild test` | Supported, used | `scripts/benchmark.sh`. |
| Read the numbers | `xcresulttool get test-results metrics` and `tests` | Supported, used | JSON with every measurement, and the result of every test. |

## Limits.json instead of Xcode baselines

Xcode's `.xcbaseline` plist is matched to one run destination record: Mac model, CPU and simulator model.
A script can write such a file without the Xcode UI. Written into an app-host project, it gave a native failure
and a native pass. The plist format is not documented, and each destination needs its own record.

`Limits.json` is a policy choice instead: one reviewed number per test and metric, the same on every machine.
Loose limits do not make a measurement machine-independent. They only decide what counts as a failure.

| | Xcode `.xcbaseline` | `Limits.json` |
|---|---|---|
| Applies to | One exact run destination | Every machine |
| Fails when | The average moves more than a percent from the baseline (Xcode default 10%) | The average is over a maximum, or under a `{"min": N}` minimum |
| Format | Undocumented plist, normally set in the Xcode UI | Plain JSON, reviewed in git |
| Catches | Small regressions, on that destination only | Big regressions only (3x for time and counts, 1.5x for memory) |

For small changes, `--base` compares a run with an earlier run on the same machine.
The generated limits accept a 200% increase in time or a 50% increase in memory. They are not statistical bounds.
Check the reference run before you adopt them.

## Three memory numbers, and why heap growth is gated

- **Resident size** counts every resident page.
- **Physical footprint** is the dirty and compressed memory the kernel charges to the process.
  A memory kill (jetsam) compares against it.
- **Malloc bytes in use** is the live heap, as the allocator sees it.

In one process, `measure` repeats the block. The first whole parse of 10 MB grew the footprint by 373 MiB.
The second and third grew it by 13 MiB, with the absolute footprint near 50 MiB. The heap number was 458 MiB each time.
After the first parse the allocator keeps the pages, and the kernel stops charging the reused ones.
So on a repeated run the footprint shows what is charged, not what the code touched.

That is why "Peak Heap Growth" is the gated memory number. "Peak Footprint" stays in the report as the absolute
number that a memory kill uses. It has no direction, so no limit and no `--max-regression` gate uses it.
Between a single-test run and a full-suite run of the same commit it moved 12%, because of the tests that ran before.
The heap number does not count `vm_allocate` or `mmap` memory, such as image buffers. The parser uses neither.

## What the sampler costs and misses

- A 1 ms interval is a request. The thread can be scheduled late, so a peak shorter than a few milliseconds can be missed.
- Reading the heap takes the malloc zone locks. A 1 ms heap read slowed an allocation-heavy parse by 40%.
  So the heap is read every 5 ms, and the footprint every 1 ms.
- The sampler thread's CPU counts in a process-wide `XCTCPUMetric`. For pure CPU numbers, run a test without the sampler.
- Each interval has a generation, and the stop waits for the sampler thread. A late read cannot change a finished
  or a later interval. `testLateReadFromAnEarlierIntervalIsDropped` covers this.

## How a custom metric plugs in

`XCTMetric` is a public protocol. A class that adopts it and `NSCopying` gets `willBeginMeasuring`,
`didStopMeasuring` and `reportMeasurements(from:to:)` from XCTest. Its measurements land in the result bundle
next to Apple's.

XCTest calls the hooks on a background queue while the main thread waits for every metric to start.
A `DispatchQueue.main.sync` in a hook deadlocks the run. So the metrics use `CFRunLoopAddTimer` and
`CADisplayLink.add(to:forMode:)` from that queue.

## Noise between two runs of the same code

Two Debug runs of the same code on one simulator:

| Metric | Change | Why |
|---|---|---|
| Clock, CPU time, CPU instructions | under 5% | Stable. |
| Longest main thread stall, during a scroll | +30% | One slow frame moves the maximum. |
| Late frame time, during a scroll | +32% | The same. |
| Peak footprint, absolute | +31% | It depends on the tests that ran before in the same process. |

So use `--max-regression` on clock and CPU time, or with a wide margin.

## Measurement notes

- `measure` runs the block `iterationCount + 1` times. The first run is a warm-up and is not recorded.
- A time is the sum of the whole block. A block that types 100 keys reports the time for 100 keys.
- The clock stops where the block ends. To time an event inside it, use `invocationOptions = [.manuallyStop]`
  and call `stopMeasuring()`.
- Compute fixture data, such as expected block counts, before the block, so it is not timed.
- `FrameHitchMetric` fits a block that turns the run loop the whole time, like a scroll. Typing turns the run loop
  for 1 ms per key, so a display link sees few frames, and all of them are late.

## Device runs

A Swift package test target cannot run on a device. `xcodebuild` stops with
"Tool-hosted testing is unavailable on device destinations". A device run needs a small host app with a unit test
target that holds the benchmark files and links the packages. `scripts/benchmark.sh` runs on a simulator only.
