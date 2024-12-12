import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import Testing

@Suite("Fetch Nodes Repository Functionality")
struct FetchNodesRepositoryTests {
    @Suite("When Fetching Nodes Successfully")
    struct SuccessCases {
        @Test("Emits all events in the correct order")
        func emitsAllEvents() async throws {
            let progressSteps = [0.0, 0.5, 1.0]
            let expectedEvents = makeEvents(progress: progressSteps)
            let sut = makeSUT(
                totalBytes: 2,
                progressSteps: progressSteps
            )
            
            let receivedEvents = try await collectEvents(from: sut)
            
            #expect(receivedEvents.count == expectedEvents.count, "Mismatch in number of events. Expected count: \(expectedEvents.count), received count: \(receivedEvents.count)")
            
            #expect(receivedEvents == expectedEvents)
        }
    }
    
    @Suite("When Fetching Nodes Emits Temporary Errors")
    struct TemporaryErrorCases {
        @Test(
            "Emits temporary error events",
            arguments: WaitingReasonEntity.allCases
        )
        func emitsTemporaryErrorEvents(waitingReason: WaitingReasonEntity) async throws {
            let sut = makeSUT(
                temporaryError: MockError(errorType: .anyFailingErrorType),
                waitingReason: waitingReason
            )
            let receivedEvents = try await collectEvents(from: sut)
            
            #expect(receivedEvents.contains {
                if case .temporaryError(let entity, let reason) = $0 {
                    return entity.type == .fetchNodes && reason == waitingReason
                }
                return false
            })
        }
    }
    
    // MARK: - Helper Functions
    
    private static func makeSUT(
        totalBytes: Int64 = 10,
        progressSteps: [Double] = [],
        temporaryError: MockError = MockError(errorType: .apiOk),
        waitingReason: WaitingReasonEntity = .none
    ) -> FetchNodesRepository {
        let sdk = MockSdk(
            fetchNodesTotalBytes: totalBytes,
            fetchNodesProgressSteps: progressSteps,
            fetchNodesErrorType: temporaryError.type,
            retryReason: waitingReason.toRetry()
        )
        return FetchNodesRepository(sdk: sdk)
    }
    
    private static func collectEvents(from sut: FetchNodesRepository) async throws -> [RequestEventEntity] {
        let asyncSequence = try sut.fetchNodes()
        var receivedEvents: [RequestEventEntity] = []
        for try await event in asyncSequence {
            receivedEvents.append(event)
        }
        return receivedEvents
    }
    
    private static func makeFetchNodesRequest(
        transferredBytes: Int64 = 0,
        totalBytes: Int64 = 0
    ) -> MockRequest {
        MockRequest(
            handle: 1,
            requestType: .MEGARequestTypeFetchNodes,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes
        )
    }
    
    private static func makeEvents(progress: [Double]) -> [RequestEventEntity] {
        progress.map {
            switch $0 {
            case 0.0: RequestEventEntity.start(RequestEntity(type: .fetchNodes, progress: $0))
            case 1.0: RequestEventEntity.finish(RequestEntity(type: .fetchNodes, progress: $0))
            default: RequestEventEntity.update(RequestEntity(type: .fetchNodes, progress: $0))
            }
        }
    }
}
