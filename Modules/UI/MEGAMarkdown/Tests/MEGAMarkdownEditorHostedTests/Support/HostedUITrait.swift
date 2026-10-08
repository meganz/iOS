import Foundation
import Testing

/// Hosted editor tests share the main thread, the first responder and app-wide notifications.
/// Tests with this trait run one at a time, also across suites, so they do not change each other's results.
/// A test over its `.timeLimit` is cancelled. The lock is free again once the test returns.
struct HostedUITrait: SuiteTrait, TestTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
        await HostedUILock.shared.lock()
        do {
            try await function()
        } catch {
            await HostedUILock.shared.unlock()
            throw error
        }
        await HostedUILock.shared.unlock()
    }
}

extension Trait where Self == HostedUITrait {
    static var hostedUI: Self { Self() }
}

/// A first-in, first-out lock for `HostedUITrait`.
actor HostedUILock {
    static let shared = HostedUILock()
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func lock() async {
        guard isLocked else {
            isLocked = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func unlock() {
        guard !waiters.isEmpty else {
            isLocked = false
            return
        }
        waiters.removeFirst().resume()
    }
}
