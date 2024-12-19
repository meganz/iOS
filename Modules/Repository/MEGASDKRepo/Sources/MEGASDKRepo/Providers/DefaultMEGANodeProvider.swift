import MEGADomain
import MEGASdk

public struct DefaultMEGANodeProvider: MEGANodeProviderProtocol {
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        await sdk.node(for: handle)
    }
}
