import MEGADomain

struct MEGAHandleRepository: MEGAHandleRepositoryProtocol {
    static var newRepo: MEGAHandleRepository = MEGAHandleRepository()
    
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        MEGASdk.base64Handle(forUserHandle: handle)
    }
    
    func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity? {
        MEGASdk.handle(forBase64Handle: handle)
    }
}
