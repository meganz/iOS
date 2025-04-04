import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public final class MockMEGAStore: @unchecked Sendable {
    
    public enum Invocation: Sendable, Equatable {
        case insertOrUpdateRecentlyOpenedNode
        case fetchRecentlyOpenedNodes
        case clearRecentlyOpenedNodes
        case clearRecentlyOpenedNode(fingerprint: String)
    }
    
    @Atomic public var invocations = [Invocation]()
    
    public init() { }
}

// MARK: MockMEGAStore+RecentlyOpenedNodesMEGAStoreProtocol

extension MockMEGAStore: RecentlyOpenedNodesMEGAStoreProtocol {
    
    public func insertOrUpdateRecentlyOpenedNode(fingerprint: String, destination: Int, timescale: Int?, lastOpenedDate: Date) {
        $invocations.mutate { $0.append(.insertOrUpdateRecentlyOpenedNode) }
    }
    
    public func fetchRecentlyOpenedNodes() async throws -> [RecentlyOpenedNodeRepositoryDTO] {
        $invocations.mutate { $0.append(.fetchRecentlyOpenedNodes) }
        return []
    }
    
    public func clearRecentlyOpenedNodes() async throws {
        $invocations.mutate { $0.append(.clearRecentlyOpenedNodes) }
    }
    
    public func clearRecentlyOpenedNode(for fingerprint: String) async throws(RecentlyOpenedNodesErrorEntity) {
        $invocations.mutate { $0.append(.clearRecentlyOpenedNode(fingerprint: fingerprint)) }
    }
}
