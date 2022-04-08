
protocol GetFeedbackInfoUseCaseProtocol {
    func getFeedback() -> FeedbackEntity
}

struct GetFeedbackInfoUseCase<T: FeedbackRepositoryProtocol>: GetFeedbackInfoUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func getFeedback() -> FeedbackEntity {
        repo.getFeedback()
    }
}
