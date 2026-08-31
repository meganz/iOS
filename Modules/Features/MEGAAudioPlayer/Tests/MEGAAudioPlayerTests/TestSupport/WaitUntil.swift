import Foundation
import Testing

/// Re-checks `condition` until it holds, so a test spends only as long as the work
/// actually needs rather than a fixed sleep.
///
/// Bounded by a wall-clock deadline rather than a spin count: a condition that
/// settles only after work hops off the main actor needs real time to pass, not
/// just another turn of the main queue. A condition that already holds returns on
/// the first check, so a passing test pays nothing for the deadline.
@MainActor
func wait(
    until condition: () -> Bool,
    timeout: Duration = .seconds(5),
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(1))
    }
    guard condition() else {
        Issue.record("Timed out waiting for the expected state", sourceLocation: sourceLocation)
        return
    }
}
