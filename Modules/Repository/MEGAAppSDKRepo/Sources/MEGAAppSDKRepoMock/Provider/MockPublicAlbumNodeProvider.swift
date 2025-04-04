import MEGAAppSDKRepo
import MEGADomain
import MEGASdk

public final class MockPublicAlbumNodeProvider: PublicAlbumNodeProviderProtocol, @unchecked Sendable {
    
    private let nodes: [MEGANode]
    
    public var clearCacheCalled = 0
    
    public init(nodes: [MEGANode] = []) {
        self.nodes = nodes
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        nodes.first(where: { $0.handle == handle })
    }
    
    public func publicPhotoNode(for element: SetElementEntity) async throws -> MEGANode? {
        nodes.first(where: { $0.handle == element.nodeId })
    }
    
    public func clearCache() async {
        clearCacheCalled += 1
    }
}
