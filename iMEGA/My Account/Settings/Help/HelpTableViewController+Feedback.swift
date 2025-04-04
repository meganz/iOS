import MEGAAppSDKRepo
import MEGADomain

extension HelpTableViewController {
    @objc func createSendFeedbackViewModel() -> SendFeedbackViewModel {
        SendFeedbackViewModel(accountUseCase: AccountUseCase(repository: AccountRepository.newRepo))
    }
    
    @objc func sendUserFeedback() {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        
        Task { @MainActor in
            do {
                let feedbackEntity = await sendFeedbackViewModel.getFeedback()
                SendFeedbackViewRouter(presenter: self, feedbackEntity: feedbackEntity).start()
            }
        }
    }
}
