@testable import MEGA

class MockOfflineInfoRepository: OfflineInfoRepositoryProtocol, @unchecked Sendable {
    var result: Result<Void, NodeInfoError>
    
    private(set) var localPathfromNodeCallCount = 0
    private let isOffline: Bool
    /// Which nodes the offline store knows about, for the tests that need some nodes saved offline
    /// and others not. `nil` falls back to `result` / `isOffline` for every node.
    private let availableOfflineHandles: Set<MEGAHandle>?
    
    init(
        result: Result<Void, NodeInfoError> = .success,
        isOffline: Bool = false,
        availableOfflineHandles: Set<MEGAHandle>? = nil
    ) {
        self.result = result
        self.isOffline = isOffline
        self.availableOfflineHandles = availableOfflineHandles
    }
    
    func fetchTracks(from files: [String]?) -> [TrackEntity]? {
        switch result {
        case .failure: return nil
        case .success: return TrackEntity.mockArray
        }
    }
    
    func offlineFileURL(for node: MEGANode) -> URL? {
        localPathfromNodeCallCount += 1
        switch result {
        case .failure: return nil
        case .success: return TrackEntity.mockURL
        }
    }
    
    func offlineFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL] {
        localPathfromNodeCallCount += 1
        switch result {
        case .failure: return [:]
        case .success: return nodes.reduce(into: [MEGANode: URL]()) { $0[$1] = TrackEntity.mockURL }
        }
    }
    
    func offlineSavedFileURL(for node: MEGANode) -> URL? {
        offlineSavedFileURLs(for: [node])[node]
    }
    
    func offlineSavedFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL] {
        localPathfromNodeCallCount += 1
        return nodes.reduce(into: [MEGANode: URL]()) { result, node in
            guard isNodeAvailableOffline(node), case .success = self.result else { return }
            result[node] = TrackEntity.mockURL
        }
    }
    
    func isNodeAvailableOffline(_ node: MEGANode) -> Bool {
        guard let availableOfflineHandles else { return isOffline }
        return availableOfflineHandles.contains(node.handle)
    }
}
