@testable import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import Testing

@Suite("Download transfer quota state provider test suite", .timeLimit(.minutes(1)))
struct DownloadTransferQuotaStateProviderTests {

    /// `TransferQuotaStateEntity` is not `CaseIterable`, so the cases under test are listed here.
    static let allStates: [TransferQuotaStateEntity] = [.green, .orange, .red]

    // MARK: - TransferQuotaStateNotifying -> TransferQuotaStateProviding

    @Test("Notified states reach the subscriber in order")
    func notifiedStatesReachSubscriberInOrder() async {
        let sut = DownloadTransferQuotaStateProvider()
        let states = sut.states

        sut.notify(state: .orange)
        sut.notify(state: .red)

        #expect(await states.collect(2) == [.orange, .red])
    }

    @Test("Every state case is delivered unchanged", arguments: allStates)
    func everyStateCaseIsDelivered(state: TransferQuotaStateEntity) async {
        let sut = DownloadTransferQuotaStateProvider()
        let states = sut.states

        sut.notify(state: state)

        #expect(await states.collect(1) == [state])
    }

    @Test("Each subscriber receives every notified state")
    func eachSubscriberReceivesEveryNotifiedState() async {
        let sut = DownloadTransferQuotaStateProvider()
        let first = sut.states
        let second = sut.states

        sut.notify(state: .green)

        async let firstReceived = first.collect(1)
        async let secondReceived = second.collect(1)

        #expect(await firstReceived == [.green])
        #expect(await secondReceived == [.green])
    }

    @Test("Notifying with no subscriber is a no-op and is not replayed to a later subscriber")
    func statesAreNotReplayedToLaterSubscribers() async {
        let sut = DownloadTransferQuotaStateProvider()

        sut.notify(state: .red)

        let states = sut.states
        sut.notify(state: .green)

        #expect(await states.collect(1) == [.green])
    }

    @Test("States notified before iteration starts are buffered, not dropped")
    func statesNotifiedBeforeIterationAreBuffered() async {
        let sut = DownloadTransferQuotaStateProvider()
        let states = sut.states
        let expected = Self.allStates

        for state in expected {
            sut.notify(state: state)
        }

        #expect(await states.collect(expected.count) == expected)
    }

    // MARK: - Subscription teardown

    @Test("A cancelled subscription is torn down without affecting the remaining subscribers")
    func cancelledSubscriptionDoesNotAffectRemainingSubscribers() async {
        let sut = DownloadTransferQuotaStateProvider()
        let survivor = sut.states

        let cancelled = Task {
            for await _ in sut.states { }
        }
        await Task.yield()
        cancelled.cancel()
        await cancelled.value

        sut.notify(state: .orange)

        #expect(await survivor.collect(1) == [.orange])
    }

    @Test("A subscription discarded before iterating is torn down and the provider keeps working")
    func discardedSubscriptionIsTornDown() async {
        let sut = DownloadTransferQuotaStateProvider()

        for _ in 0..<3 {
            _ = sut.states
        }

        let states = sut.states
        sut.notify(state: .red)

        #expect(await states.collect(1) == [.red])
    }

    // MARK: - Thread safety

    @Test("Concurrent notifications are all delivered")
    func concurrentNotificationsAreAllDelivered() async {
        let sut = DownloadTransferQuotaStateProvider()
        let states = sut.states
        let producers = 3
        let notificationsPerProducer = 10
        let expectedCount = producers * notificationsPerProducer

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<producers {
                group.addTask {
                    for _ in 0..<notificationsPerProducer {
                        sut.notify(state: .orange)
                    }
                }
            }
        }

        let received = await states.collect(expectedCount)
        #expect(received.count == expectedCount)
        #expect(received.allSatisfy { $0 == .orange })
    }

    @Test("Concurrent subscriptions and teardowns leave the provider usable")
    func concurrentSubscriptionsAndTeardownsAreSafe() async {
        let sut = DownloadTransferQuotaStateProvider()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    for _ in 0..<10 {
                        let subscription = Task {
                            for await _ in sut.states { }
                        }
                        await Task.yield()
                        subscription.cancel()
                        await subscription.value
                    }
                }
            }
        }

        let states = sut.states
        sut.notify(state: .green)

        #expect(await states.collect(1) == [.green])
    }

    // MARK: - Shared instance

    @Test("Shared instance is a singleton")
    func sharedInstanceIsASingleton() {
        #expect(DownloadTransferQuotaStateProvider.shared === DownloadTransferQuotaStateProvider.shared)
    }

    // MARK: - Protocol conformances

    @Test("States flow from the notifying protocol to the providing protocol")
    func statesFlowThroughProtocolExistentials() async {
        let sut = DownloadTransferQuotaStateProvider()
        let provider: any TransferQuotaStateProviding = sut
        let notifier: any TransferQuotaStateNotifying = sut

        let states = provider.states
        notifier.notify(state: .orange)

        #expect(await states.collect(1) == [.orange])
    }
}

// MARK: - Helpers

private extension AnyAsyncSequence {
    /// Collects the first `count` elements, then stops iterating so the subscription is torn down.
    func collect(_ count: Int) async -> [Element] {
        var elements: [Element] = []
        for await element in self {
            elements.append(element)
            if elements.count == count { break }
        }
        return elements
    }
}
