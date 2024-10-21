import MEGADomain

public struct MockMEGAHandleRepository: MEGAHandleRepositoryProtocol {
    public static let newRepo: MockMEGAHandleRepository = MockMEGAHandleRepository()
    
    public init() {}

    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        String(describing: handle)
    }
    
    public func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity? {
        HandleEntity(handle)
    }
    
    public func handle(forBase64UserHandle handle: Base64HandleEntity) -> HandleEntity? {
        HandleEntity(handle)
    }
}
