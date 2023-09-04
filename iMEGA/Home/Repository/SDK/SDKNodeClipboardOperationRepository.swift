class SDKNodeClipboardOperationRepository: NSObject, MEGARequestDelegate {
    enum ClipboardOperation {
        case move
        case copy
        
        var requestType: MEGARequestType {
            switch self {
            case .move:
                return .MEGARequestTypeMove
            case .copy:
                return .MEGARequestTypeCopy
            }
        }
    }
    
    private let sdk: MEGASdk
    typealias CompletionBlock = (MEGANode) -> Void
    private var completionBlock: CompletionBlock?
    private var permittedOperations = Set<ClipboardOperation>()
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk,
           permittedOperations.map({ $0.requestType }).contains(request.type),
           let node = api.node(forHandle: request.nodeHandle),
           let block = completionBlock {
           block(node)
        }
    }
    
    func onClipboardOperationComplete(
        permittedOperations: Set<ClipboardOperation>,
        withCompletionBlock completionBlock: @escaping CompletionBlock
    ) {
        self.permittedOperations = self.permittedOperations.union(permittedOperations)
        self.completionBlock = completionBlock
    }
}
