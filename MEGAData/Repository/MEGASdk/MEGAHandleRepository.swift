import MEGADomain

struct MEGAHandleRepository: MEGAHandleRepositoryProtocol {
    static var newRepo: MEGAHandleRepository = MEGAHandleRepository()
    
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        MEGASdk.base64Handle(forUserHandle: handle)
    }
}
