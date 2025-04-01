import MEGADomain
import MEGADomainMock
import Testing

@Suite("Request stats progress use case test suite")
struct RequestStatProgressUseCaseTests {
    @Test("Only process reqStatProgress events. Two events received, one is reqStatProgress type")
    func testRequestStatsProgresss() async {
        let repo = MockEventRepository.newRepo
        let sut = RequestStatProgressUseCase(repo: repo)
        let mockEvents = [EventEntity(type: .reqStatProgress, number: 0), EventEntity(type: .commitDB, number: 0)]
        
        let task = Task {
            var events: [EventEntity] = []
            for await event in sut.requestStatsProgress {
                events.append(event)
            }
            return events
        }
        
        mockEvents.forEach {
            repo.simulateEvent($0)
        }
        
        repo.simulateEventCompletion()
        
        let receivedEvent = await task.value
        #expect(receivedEvent.count == 1)
    }
}
