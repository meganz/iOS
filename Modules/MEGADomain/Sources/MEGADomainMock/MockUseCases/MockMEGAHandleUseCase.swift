import MEGADomain

public struct MockMEGAHandleUseCase : MEGAHandleUseCaseProtocol {
    private let base64Handle: Base64HandleEntity?
    private let userHandle: HandleEntity?
    
    public init(base64Handle: Base64HandleEntity? = nil, userHandle: HandleEntity? = nil) {
        self.base64Handle = base64Handle
        self.userHandle = userHandle
    }
    
    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        base64Handle
    }
    
    public func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity? {
        userHandle
    }
}
