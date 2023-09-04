final class SDKTransferListenerRepository: NSObject, MEGATransferDelegate {
    private let sdk: MEGASdk
    
    typealias Handler = ((_ node: MEGANode,
                          _ isStreamingTransfer: Bool,
                          _ transferType: MEGATransferType) -> Void)
    
    var startHandler: Handler?
    var updateHandler: ((_ node: MEGANode,
                         _ isStreamingTransfer: Bool,
                         _ transferType: MEGATransferType,
                         _ progress: Float,
                         _ speed: Int64) -> Void)?
    var endHandler: Handler?
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        if let node = api.node(forHandle: transfer.nodeHandle) {
            startHandler?( node, transfer.isStreamingTransfer, transfer.type)
        }
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        if let node = api.node(forHandle: transfer.nodeHandle) {
            
            let progress = transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue
            let speed = transfer.speed?.int64Value ?? 0
            updateHandler?( node, transfer.isStreamingTransfer, transfer.type, progress, speed)
        }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if let node = api.node(forHandle: transfer.nodeHandle) {
            endHandler?( node, transfer.isStreamingTransfer, transfer.type)
        }
    }
}
