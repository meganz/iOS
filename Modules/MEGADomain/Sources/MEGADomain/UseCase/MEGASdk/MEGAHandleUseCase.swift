
public protocol MEGAHandleUseCaseProtocol {
    func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity?
}

public struct MEGAHandleUseCase<T: MEGAHandleRepositoryProtocol>: MEGAHandleUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func base64Handle(forUserHandle handle: HandleEntity) -> Base64HandleEntity? {
        repo.base64Handle(forUserHandle: handle)
    }
}
