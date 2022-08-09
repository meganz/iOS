

extension MainTabBarController {
    
    @objc func createPSAViewModel() -> PSAViewModel? {
        let router = PSAViewRouter(tabBarController: self)
        let repo = PSARepository(sdk: MEGASdkManager.sharedMEGASdk())
        let useCase = PSAUseCase(repo: repo)
        return PSAViewModel(router: router, useCase: useCase)
    }
    
    @objc func showPSAViewIfNeeded(_ psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.showPSAViewIfNeeded)
    }
    
    @objc func hidePSAView(_ hide: Bool, psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.setPSAViewHidden(hide))
    }
    
    @objc func adjustPSAFrameIfNeeded(psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.adjustPSAFrameIfNeeded)
    }
}
