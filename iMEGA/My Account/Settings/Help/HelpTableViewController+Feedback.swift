import MEGADomain

extension HelpTableViewController {
    @objc func sendUserFeedback() {
        let getFeedbackInfoUC = GetFeedbackInfoUseCase(repo: FeedbackRepository.newRepo)
        
        sendFeedbackRouter = SendFeedbackViewRouter(presenter: self, feedbackEntity: getFeedbackInfoUC.getFeedback())
        sendFeedbackRouter?.start()
    }
}
