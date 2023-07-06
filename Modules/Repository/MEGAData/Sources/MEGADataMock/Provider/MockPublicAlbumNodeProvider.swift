import MEGAData
import MEGADomain
import MEGASdk

public final class MockPublicAlbumNodeProvider: PublicAlbumNodeProviderProtocol {
    private let node: MEGANode?
    
    public var clearCacheCalled = 0
    
    public init(node: MEGANode? = nil) {
        self.node = node
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        node
    }
    
    public func publicPhotoNode(for element: SetElementEntity) async throws -> MEGANode? {
        node
    }
    
    public func clearCache() async {
        clearCacheCalled += 1
    }
}
