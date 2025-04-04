import MEGADomain
import MEGASdk

public struct FolderLinkMEGANodeProvider: MEGANodeProviderProtocol {
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        return sdk.authorizeNode(node)
    }
}
