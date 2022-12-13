
protocol GetFeedbackInfoUseCaseProtocol {
    func getFeedback() -> FeedbackEntity
}

public struct GetFeedbackInfoUseCase<T: FeedbackRepositoryProtocol>: GetFeedbackInfoUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func getFeedback() -> FeedbackEntity {
        repo.getFeedback()
    }
}
