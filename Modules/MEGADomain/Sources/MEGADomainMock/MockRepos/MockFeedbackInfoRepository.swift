import MEGADomain

public struct MockFeedbackInfoRepository: FeedbackRepositoryProtocol {
    public static var newRepo: MockFeedbackInfoRepository {
        MockFeedbackInfoRepository()
    }
    
    private let feedbackEntity = FeedbackEntity(toEmail: "email@mega.nz",
                                        subject: "subject",
                                        messageBody: "body",
                                        logsFileName: "logsFileName")
    
    public func getFeedback() -> FeedbackEntity {
        feedbackEntity
    }
}
