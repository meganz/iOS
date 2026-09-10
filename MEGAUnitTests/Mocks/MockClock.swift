import Foundation

/// A `Clock` whose time only moves when a test moves it, so timing rules can be exercised without
/// waiting on real time.
///
/// `sleep(until:tolerance:)` parks its caller until `advance(by:)` carries the clock past the
/// deadline, or until the sleeping task is cancelled. `waitForSleepers(_:)` is how a test waits for
/// a sleep to be registered, so advancing never races the code being driven.
final class MockClock: Clock, @unchecked Sendable {
    struct Instant: InstantProtocol {
        /// How far past the clock's zero this instant is.
        let offset: Duration

        func advanced(by duration: Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        func duration(to other: Instant) -> Duration {
            other.offset - offset
        }

        static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private struct Sleeper {
        let id: UUID
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }

    let minimumResolution: Duration = .zero

    private let lock = NSLock()
    private var currentInstant = Instant(offset: .zero)
    private var sleepers = [Sleeper]()
    /// Sleeps cancelled before they parked, which their own registration then has to answer for.
    private var cancelledSleeperIDs = Set<UUID>()

    var now: Instant {
        lock.withLock { currentInstant }
    }

    /// How many sleeps are parked on this clock right now.
    var sleeperCount: Int {
        lock.withLock { sleepers.count }
    }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        let id = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                switch register(id: id, deadline: deadline, continuation: continuation) {
                case .cancelled: continuation.resume(throwing: CancellationError())
                case .elapsed: continuation.resume()
                case .parked: break
                }
            }
        } onCancel: {
            wake(id: id)?.resume(throwing: CancellationError())
        }
    }

    /// Moves time forward, waking every sleep whose deadline has passed.
    func advance(by duration: Duration) {
        let due: [Sleeper] = lock.withLock {
            currentInstant = currentInstant.advanced(by: duration)
            let elapsed = sleepers.filter { $0.deadline <= currentInstant }
            sleepers.removeAll { $0.deadline <= currentInstant }
            return elapsed
        }

        due.forEach { $0.continuation.resume() }
    }

    /// Suspends until `count` sleeps are parked on this clock, so a test can advance without racing
    /// the code it is driving.
    func waitForSleepers(_ count: Int = 1, maximumYields: Int = 1000) async {
        var yields = 0
        while sleeperCount < count, yields < maximumYields {
            yields += 1
            await Task.yield()
        }
    }

    // MARK: - Private

    private enum Registration {
        case cancelled
        case elapsed
        case parked
    }

    private func register(
        id: UUID,
        deadline: Instant,
        continuation: CheckedContinuation<Void, any Error>
    ) -> Registration {
        lock.withLock {
            // A sleep can be cancelled before it ever parks, in which case its cancellation is
            // waiting here for it rather than the other way round.
            if cancelledSleeperIDs.remove(id) != nil {
                return .cancelled
            }
            guard currentInstant < deadline else { return .elapsed }
            sleepers.append(Sleeper(id: id, deadline: deadline, continuation: continuation))
            return .parked
        }
    }

    /// Takes a parked sleep out, or records the cancellation for a sleep that has yet to park.
    private func wake(id: UUID) -> CheckedContinuation<Void, any Error>? {
        lock.withLock {
            guard let index = sleepers.firstIndex(where: { $0.id == id }) else {
                cancelledSleeperIDs.insert(id)
                return nil
            }
            return sleepers.remove(at: index).continuation
        }
    }
}
