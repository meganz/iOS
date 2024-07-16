public protocol MEGAHandleRepositoryProtocol: Sendable, RepositoryProtocol {
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity?
    func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity?
    func handle(forBase64UserHandle handle: Base64HandleEntity) -> HandleEntity?
}
