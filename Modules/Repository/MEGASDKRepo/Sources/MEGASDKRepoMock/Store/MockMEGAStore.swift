import MEGADomain
import MEGASDKRepo
import MEGASwift

public final class MockMEGAStore: @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case insertOrUpdateMediaDestination
        case fetchRecentlyOpenedNodes
        case clearRecentlyOpenedNodes
    }
    
    @Atomic public var invocations = [Invocation]()
    
    public init() { }
}

// MARK: MockMEGAStore+RecentlyOpenedNodesMEGAStoreProtocol

extension MockMEGAStore: RecentlyOpenedNodesMEGAStoreProtocol {
    
    public func insertOrUpdateMediaDestination(fingerprint: String, destination: Int, timescale: Int?) {
        $invocations.mutate { $0.append(.insertOrUpdateMediaDestination) }
    }
    
    public func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO] {
        $invocations.mutate { $0.append(.fetchRecentlyOpenedNodes) }
        return []
    }
    
    public func clearRecentlyOpenedNodes() async throws {
        $invocations.mutate { $0.append(.clearRecentlyOpenedNodes) }
    }
}
