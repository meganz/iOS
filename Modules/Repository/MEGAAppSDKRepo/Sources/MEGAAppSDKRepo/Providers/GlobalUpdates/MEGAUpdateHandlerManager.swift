import MEGADomain
import MEGASdk
import MEGASwift

final class MEGAUpdateHandlerManager: NSObject, MEGADelegate, @unchecked Sendable {
    @Atomic
    private var handlers: [MEGAUpdateHandler] = []
    private let sdk: MEGASdk
    private let sdkDelegateQueue = DispatchQueue(label: "nz.mega.MEGASDKRepo.MEGAUpdateHandlerManager.delegateQueue")
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdkDelegateQueue.async {
            sdk.add(self)
        }
    }
    
    deinit {
        sdk.remove(self)
    }
    
    static let shared = MEGAUpdateHandlerManager(sdk: .sharedSdk)
    static let sharedFolderLink = MEGAUpdateHandlerManager(sdk: .sharedFolderLinkSdk)
    
    // MARK: - Global events
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList) {
        let nodeEntities = nodeList.toNodeEntities()
        handlers.forEach { $0.onNodesUpdate?(nodeEntities) }
    }
    
    func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList) {
        let users = userList.toUserEntities()
        handlers.forEach { $0.onUsersUpdate?(users) }
    }
    
    func onUserAlertsUpdate(_ api: MEGASdk, userAlertList: MEGAUserAlertList) {
        let userAlerts = userAlertList.toUserAlertEntities()
        handlers.forEach { $0.onUserAlertsUpdate?(userAlerts) }
    }
    
    func onContactRequestsUpdate(_ api: MEGASdk, contactRequestList: MEGAContactRequestList) {
        let contactRequests = contactRequestList.toContactRequestEntities()
        handlers.forEach { $0.onContactRequestsUpdate?(contactRequests) }
    }
    
    func onEvent(_ api: MEGASdk, event: MEGAEvent) {
        handlers.forEach { $0.onEvent?(event.toEventEntity()) }
    }
    
    // MARK: - Request events
    func onRequestStart(_ api: MEGASdk, request: MEGARequest) {
        handlers.forEach { $0.onRequestStart?(request.toRequestEntity()) }
    }
    
    func onRequestUpdate(_ api: MEGASdk, request: MEGARequest) {
        handlers.forEach { $0.onRequestUpdate?(request.toRequestEntity()) }
    }
    
    func onRequestTemporaryError(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        handlers.forEach { $0.onRequestTemporaryError?(RequestResponseEntity(requestEntity: request.toRequestEntity(), error: error.toErrorEntity())) }
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        handlers.forEach { $0.onRequestFinish?(RequestResponseEntity(requestEntity: request.toRequestEntity(), error: error.toErrorEntity())) }
    }
    
    // MARK: - Transfer events
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        let result: Result<TransferEntity, ErrorEntity> = switch error.type {
        case .apiOk: .success(transfer.toTransferEntity())
        default: .failure(error.toErrorEntity())
        }
        
        handlers.forEach { $0.onTransferFinish?(result) }
    }
    
    // MARK: - Handler management
    func add(handler: MEGAUpdateHandler) {
        $handlers.mutate { $0.append(handler) }
    }
    
    func remove(handler: MEGAUpdateHandler) {
        $handlers.mutate { $0.remove(object: handler) }
    }
}
