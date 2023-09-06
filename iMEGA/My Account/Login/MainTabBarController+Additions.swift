import ChatRepo
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension MainTabBarController {
    
    private var shouldUseNewHomeSearchResults: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newHomeSearch)
    }
    
    @objc func makeHomeViewController() -> UIViewController {
        HomeScreenFactory().createHomeScreen(
            from: self,
            newHomeSearchResultsEnabled: shouldUseNewHomeSearchResults
        )
    }
    
    @objc func createPSAViewModel() -> PSAViewModel? {
        let router = PSAViewRouter(tabBarController: self)
        let useCase = PSAUseCase(repo: PSARepository.newRepo)
        return PSAViewModel(router: router, useCase: useCase)
    }
    
    @objc func showPSAViewIfNeeded(_ psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.showPSAViewIfNeeded)
    }
    
    @objc func hidePSAView(_ hide: Bool, psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.setPSAViewHidden(hide))
    }
    
    @objc func updateUnreadChatsOnBackButton() {
        
        if let chatVC = existingChatRoomsListViewController {
            chatVC.assignBackButton()
        }
    }
    
    @objc func createMainTabBarViewModel() -> MainTabBarCallsViewModel {
        let router = MainTabBarCallsRouter(baseViewController: self)
        let mainTabBarCallsViewModel = MainTabBarCallsViewModel(router: router,
                                                                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                                                                callUseCase: CallUseCase(repository: CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)),
                                                                chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo),
                                                                chatRoomUserUseCase: ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo, userStoreRepo: UserStoreRepository.newRepo))
        
        mainTabBarCallsViewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            
            excuteCommand(command)
        }
        
        return mainTabBarCallsViewModel
    }
    
    private func excuteCommand(_ command: MainTabBarCallsViewModel.Command) {
        switch command {
        case .showActiveCallIcon:
            phoneBadgeImageView.isHidden = unreadMessages > 0
        case .hideActiveCallIcon:
            phoneBadgeImageView.isHidden = true
        }
    }
}
