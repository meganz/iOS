
extension HelpTableViewController {
    @objc func sendUserFeedback() {
        let getFeedbackInfoUC = GetFeedbackInfoUseCase(repo: FeedbackRepository(sdk: MEGASdkManager.sharedMEGASdk(),
                                                                                bundle: .main,
                                                                                device: .current,
                                                                                locale: NSLocale.current as NSLocale,
                                                                                timeZone: NSTimeZone.local))
        
        sendFeedbackRouter = SendFeedbackViewRouter(presenter: self, feedbackEntity: getFeedbackInfoUC.getFeedback())
        sendFeedbackRouter?.start()
    }
}
