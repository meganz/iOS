public protocol MEGAHandleUseCaseProtocol: Sendable {
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity?
    func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity?
    func handle(forBase64UserHandle handle: Base64HandleEntity) -> HandleEntity?
}

public struct MEGAHandleUseCase<T: MEGAHandleRepositoryProtocol>: MEGAHandleUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        repo.base64Handle(forUserHandle: handle)
    }
    
    public func handle(forBase64Handle handle: Base64HandleEntity) -> HandleEntity? {
        repo.handle(forBase64Handle: handle)
    }
    
    public func handle(forBase64UserHandle handle: Base64HandleEntity) -> HandleEntity? {
        repo.handle(forBase64UserHandle: handle)
    }
}
