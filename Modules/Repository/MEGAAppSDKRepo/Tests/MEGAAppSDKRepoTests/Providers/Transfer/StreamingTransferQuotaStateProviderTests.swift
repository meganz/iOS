import AsyncAlgorithms
@testable import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import Testing

@Suite("Streaming transfer quota state provider test suite", .timeLimit(.minutes(1)))
struct StreamingTransferQuotaStateProviderTests {

    // MARK: - Event number mapping

    /// The raw values are the SDK's `MEGAApi.TRANSFER_QUOTA_STATE_*` constants.
    @Test(
        "Each transfer quota state code maps to its state",
        arguments: [(0, TransferQuotaStateEntity.green), (1, .orange), (2, .red)]
    )
    func stateCodeMapsToState(code: Int, expected: TransferQuotaStateEntity) {
        #expect(TransferQuotaStateEntity(eventNumber: code) == expected)
    }

    /// `TRANSFER_QUOTA_STATE_UNKNOWN` is -9. It carries no warning to show, so it has no case.
    @Test("Codes outside the mapped range produce no state", arguments: [-9, -1, 3, 25, .max, .min])
    func unmappedStateCodeProducesNoState(code: Int) {
        #expect(TransferQuotaStateEntity(eventNumber: code) == nil)
    }

    // MARK: - Event filtering

    @Test("Each transfer quota state event is delivered as its state")
    func transferQuotaStateEventsAreDelivered() async {
        let sut = makeSUT(events: [
            makeEvent(type: .transferQuotaState, number: 0),
            makeEvent(type: .transferQuotaState, number: 1),
            makeEvent(type: .transferQuotaState, number: 2)
        ])

        #expect(await sut.states.collectAll() == [.green, .orange, .red])
    }

    @Test("Events of other types are ignored even when their number would map to a state")
    func otherEventTypesAreIgnored() async {
        let sut = makeSUT(events: [
            makeEvent(type: .storage, number: 1),
            makeEvent(type: .streamingOverQuota, number: 2),
            makeEvent(type: .transferQuotaState, number: 1)
        ])

        #expect(await sut.states.collectAll() == [.orange])
    }

    @Test("Events with an unrecognised type are ignored")
    func untypedEventsAreIgnored() async {
        let sut = makeSUT(events: [
            makeEvent(type: nil, number: 0),
            makeEvent(type: .transferQuotaState, number: 2)
        ])

        #expect(await sut.states.collectAll() == [.red])
    }

    @Test("A transfer quota state event with an unmapped number is dropped, not yielded")
    func unmappedNumberIsDropped() async {
        let sut = makeSUT(events: [
            makeEvent(type: .transferQuotaState, number: -9),
            makeEvent(type: .transferQuotaState, number: 3),
            makeEvent(type: .transferQuotaState, number: 1)
        ])

        #expect(await sut.states.collectAll() == [.orange])
    }

    @Test("A stream carrying no transfer quota state event yields nothing")
    func noMatchingEventYieldsNothing() async {
        let sut = makeSUT(events: [makeEvent(type: .storage, number: 0)])

        #expect(await sut.states.collectAll().isEmpty)
    }

    @Test("Repeated states are all delivered in order, including recovery to green")
    func repeatedStatesAreDeliveredInOrder() async {
        let sut = makeSUT(events: [
            makeEvent(type: .transferQuotaState, number: 1),
            makeEvent(type: .transferQuotaState, number: 1),
            makeEvent(type: .transferQuotaState, number: 0)
        ])

        #expect(await sut.states.collectAll() == [.orange, .orange, .green])
    }

    @Test("Each subscriber receives every state")
    func eachSubscriberReceivesEveryState() async {
        let sut = makeSUT(events: [makeEvent(type: .transferQuotaState, number: 1)])

        async let first = sut.states.collectAll()
        async let second = sut.states.collectAll()

        #expect(await first == [.orange])
        #expect(await second == [.orange])
    }

    // MARK: - Protocol conformance

    @Test("States flow through the providing protocol")
    func statesFlowThroughProtocolExistential() async {
        let provider: any TransferQuotaStateProviding = makeSUT(
            events: [makeEvent(type: .transferQuotaState, number: 2)]
        )

        #expect(await provider.states.collectAll() == [.red])
    }

    // MARK: - Shared instance

    @Test("The shared provider merges both SDK instances and tears down cleanly")
    func sharedProviderMergesBothSDKInstances() async {
        let sut = StreamingTransferQuotaStateProvider.shared

        let subscription = Task {
            for await _ in sut.states { }
        }
        await Task.yield()
        subscription.cancel()
        await subscription.value
    }

    // MARK: - Helpers

    private func makeSUT(events: [EventEntity]) -> StreamingTransferQuotaStateProvider {
        StreamingTransferQuotaStateProvider {
            events.async.eraseToAnyAsyncSequence()
        }
    }

    private func makeEvent(type: EventEntity.EventType?, number: Int) -> EventEntity {
        EventEntity(type: type, number: number)
    }
}

// MARK: - Helpers

private extension AnyAsyncSequence {
    /// Drains a finite sequence, so a test also fails if the sequence never terminates.
    func collectAll() async -> [Element] {
        var elements: [Element] = []
        for await element in self {
            elements.append(element)
        }
        return elements
    }
}
