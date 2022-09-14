import MEGADomain

public struct MockMEGAHandleRepository: MEGAHandleRepositoryProtocol {
    public static var newRepo: MockMEGAHandleRepository = MockMEGAHandleRepository()
    private var base64Handle: Base64HandleEntity?
    
    public init(base64Handle: Base64HandleEntity? = "100") {
        self.base64Handle = base64Handle
    }

    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        base64Handle
    }
}
