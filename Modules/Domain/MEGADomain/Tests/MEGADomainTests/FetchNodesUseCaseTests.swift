import MEGADomain
import MEGADomainMock
import Testing

struct FetchNodesUseCaseTestSuite {
    @Suite("FetchNodes Functionality")
    struct FetchNodes {
        
        @Suite("When Repository Emits Success Events")
        struct SuccessEvents {
            private let startEvent: RequestEventEntity = .start(RequestEntity(type: .fetchNodes, progress: 0.0))
            private let updateEvent: RequestEventEntity = .update(RequestEntity(type: .fetchNodes, progress: 0.5))
            private let finishEvent: RequestEventEntity = .finish(RequestEntity(type: .fetchNodes, progress: 1.0))
            
            @Test("Emits all events in the correct order")
            func emitsAllEvents() async throws {
                let expectedEvents = [startEvent, updateEvent, finishEvent]
                let sut = makeSUT(repositoryEvents: expectedEvents)
                let asyncSequence = try sut.fetchNodes()
                
                var receivedEvents: [RequestEventEntity] = []
                for try await event in asyncSequence {
                    receivedEvents.append(event)
                }
                
                #expect(receivedEvents == expectedEvents)
            }
        }
        
        @Suite("When Repository Emits a Temporary Error")
        struct TemporaryErrorEvents {
            private let requestEntity = RequestEntity(type: .fetchNodes, progress: 0.7)
            
            @Test(
                "Emits the temporary error event",
                arguments: WaitingReasonEntity.allCases
            )
            func emitsTemporaryErrorEvent(waitingReason: WaitingReasonEntity) async throws {
                let temporaryErrorEvent = RequestEventEntity.temporaryError(requestEntity, waitingReason)
                let sut = makeSUT(repositoryEvents: [temporaryErrorEvent])
                let asyncSequence = try sut.fetchNodes()
                
                var receivedEvents: [RequestEventEntity] = []
                for try await event in asyncSequence {
                    receivedEvents.append(event)
                }
                
                #expect(receivedEvents == [temporaryErrorEvent])
            }
        }
        
        private static func makeSUT(
            repositoryEvents: [RequestEventEntity] = [],
            repositoryError: Error? = nil
        ) -> FetchNodesUseCase {
            FetchNodesUseCase(
                repository:
                    MockFetchNodesRepository(
                        events: repositoryEvents,
                        error: repositoryError
                    )
            )
        }
    }
}
