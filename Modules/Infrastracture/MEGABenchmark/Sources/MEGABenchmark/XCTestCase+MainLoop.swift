import Foundation
import XCTest

public enum MainLoopError: Error {
    case timeout(seconds: TimeInterval)
}

extension XCTestCase {
    /// Runs async main-actor work inside a `measure` block. The block of `measure` is synchronous, and a wait
    /// with a semaphore would block the main thread. This turns the main run loop until the work is done,
    /// so UI keeps drawing and the stall and hitch metrics see real frames.
    public func runOnMainLoop<T: Sendable>(
        timeout: TimeInterval = 120,
        _ body: @escaping @MainActor @Sendable () async throws -> T
    ) throws -> T {
        let box = ResultBox<T>()
        Task { @MainActor in
            do {
                box.set(.success(try await body()))
            } catch {
                box.set(.failure(error))
            }
        }
        let deadline = Date(timeIntervalSinceNow: timeout)
        while box.get() == nil {
            guard Date() < deadline else { throw MainLoopError.timeout(seconds: timeout) }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.002))
        }
        guard let result = box.get() else { throw MainLoopError.timeout(seconds: timeout) }
        return try result.get()
    }

    /// Turns the main run loop for the given time, for example to let a view settle or to type one key.
    public func turnMainLoop(for seconds: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    /// Turns the main run loop until the condition holds. Throws after the timeout.
    public func turnMainLoop(timeout: TimeInterval = 60, until condition: () -> Bool) throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !condition() {
            guard Date() < deadline else { throw MainLoopError.timeout(seconds: timeout) }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.005))
        }
    }
}

private final class ResultBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<T, any Error>?

    func set(_ result: Result<T, any Error>) {
        lock.withLock { value = result }
    }

    func get() -> Result<T, any Error>? {
        lock.withLock { value }
    }
}
