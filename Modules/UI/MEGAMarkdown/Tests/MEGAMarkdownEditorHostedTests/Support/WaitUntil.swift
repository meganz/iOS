import Foundation

struct WaitTimeout: Error, CustomStringConvertible {
    let what: String
    let seconds: Double

    var description: String { "Timed out after \(seconds) s waiting for \(what)" }
}

/// Polls `condition` on the main actor until it holds. Throws a `WaitTimeout` that names what was awaited.
@MainActor
func waitUntil(_ what: String, timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while !condition() {
        guard clock.now < deadline else {
            throw WaitTimeout(what: what, seconds: Double(timeout.components.seconds))
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}

/// Polls `value` until it returns a result. Throws a `WaitTimeout` that names what was awaited.
@MainActor
func waitForValue<T>(_ what: String, timeout: Duration = .seconds(5), _ value: () -> T?) async throws -> T {
    var found: T?
    try await waitUntil(what, timeout: timeout) {
        found = value()
        return found != nil
    }
    guard let found else { throw WaitTimeout(what: what, seconds: Double(timeout.components.seconds)) }
    return found
}
