
public protocol MEGAHandleRepositoryProtocol: RepositoryProtocol {
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity?
}
