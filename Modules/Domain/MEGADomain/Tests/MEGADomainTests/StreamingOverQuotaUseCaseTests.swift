import MEGADomain
import MEGADomainMock
import Testing

@Suite("Streaming over quota use case test suite")
struct StreamingOverQuotaUseCaseTests {
    @Test("Only process streamingOverQuota events. Two events received, one is streamingOverQuota type")
    func testLoggedOutStreamingOverQuotaUpdates() async {
        let repo = MockEventRepository()
        let sut = StreamingOverQuotaUseCase(repo: repo)
        let mockEvents = [EventEntity(type: .streamingOverQuota, number: 0), EventEntity(type: .commitDB, number: 0)]

        let task = Task {
            var events: [EventEntity] = []
            for await event in sut.loggedOutStreamingOverQuotaUpdates {
                events.append(event)
            }
            return events
        }

        mockEvents.forEach {
            repo.simulateFolderLinkEvent($0)
        }

        repo.simulateFolderLinkEventCompletion()

        let receivedEvent = await task.value
        #expect(receivedEvent.count == 1)
    }

    @Test("Ignore events raised by the main SDK instance, which AppDelegate already observes")
    func testIgnoresMainInstanceEvents() async {
        let repo = MockEventRepository()
        let sut = StreamingOverQuotaUseCase(repo: repo)

        let task = Task {
            var events: [EventEntity] = []
            for await event in sut.loggedOutStreamingOverQuotaUpdates {
                events.append(event)
            }
            return events
        }

        repo.simulateEvent(EventEntity(type: .streamingOverQuota, number: 0))
        repo.simulateFolderLinkEventCompletion()

        let receivedEvent = await task.value
        #expect(receivedEvent.isEmpty)
    }
}
