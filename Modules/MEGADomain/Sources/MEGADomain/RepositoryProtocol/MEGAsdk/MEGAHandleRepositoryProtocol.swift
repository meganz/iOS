
public protocol MEGAHandleRepositoryProtocol: RepositoryProtocol {
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity?
    func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity?
}
