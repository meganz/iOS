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
}
