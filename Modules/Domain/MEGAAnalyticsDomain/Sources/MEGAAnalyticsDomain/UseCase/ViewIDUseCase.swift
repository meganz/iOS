public protocol ViewIDUseCaseProtocol {
    func generateViewId() throws -> ViewID
}

public final class ViewIDUseCase<
    T: ViewIDRepositoryProtocol
>: ViewIDUseCaseProtocol {
    public enum GenerationError: Error {
        case emptyViewID
    }
    
    private let viewIdRepo: T
    
    public init(viewIdRepo: T) {
        self.viewIdRepo = viewIdRepo
    }
    
    public func generateViewId() throws -> ViewID {
        guard let viewId = viewIdRepo.generateViewId(), !viewId.isEmpty else {
            throw GenerationError.emptyViewID
        }
        
        return viewId
    }
    
}
