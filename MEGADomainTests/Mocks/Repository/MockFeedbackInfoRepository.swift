@testable import MEGA

struct MockFeedbackInfoRepository: FeedbackRepositoryProtocol {
    let feedbackEntity = FeedbackEntity(toEmail: "email@mega.nz",
                                        subject: "subject",
                                        messageBody: "body",
                                        logsFileName: "logsFileName")
    
    func getFeedback() -> FeedbackEntity {
        feedbackEntity
    }
}
