import MEGADomain
import MEGASdk

public struct MEGAHandleRepository: MEGAHandleRepositoryProtocol {
    public static var newRepo: MEGAHandleRepository {
        MEGAHandleRepository()
    }
    
    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        MEGASdk.base64Handle(forUserHandle: handle)
    }
    
    public func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity? {
        MEGASdk.handle(forBase64Handle: handle)
    }
    
    public func handle(forBase64UserHandle handle: Base64HandleEntity) -> HandleEntity? {
        MEGASdk.handle(forBase64UserHandle: handle)
    }
}
