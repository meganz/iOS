import Foundation
import MEGADomain
import MEGASwift

public struct MockFetchNodesRepository: FetchNodesRepositoryProtocol {
    public static var newRepo: MockFetchNodesRepository {
        MockFetchNodesRepository()
    }
    
    private let events: [RequestEventEntity]
    private let error: Error?
    
    public init(
        events: [RequestEventEntity] = [],
        error: Error? = nil
    ) {
        self.events = events
        self.error = error
    }
    
    public func fetchNodes() throws -> AnyAsyncSequence<RequestEventEntity> {
        if let error = error {
            throw error
        }
        
        let stream = AsyncThrowingStream<RequestEventEntity, Error> { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
        return stream.eraseToAnyAsyncSequence()
    }
}
