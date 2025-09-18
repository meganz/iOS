import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

extension MainTabBarController {
    func presentPSA(_ psaView: UIView) {
        addSubviewToOverlay(
            psaView,
            type: .psa,
            priority: .normal
        )
        
        shouldUpdateProgressViewLocation()
        showPSA(shouldAddSafeAreaCoverView: tabBar.isHidden)
    }
    
    func hidePSA() {
        updateOverlayLayout { [weak self] in
            self?.bottomOverlayManager?.setItemVisibility(
                for: .psa,
                hidden: true
            )
            self?.removeSafeAreaCoverView()
        }
    }
    
    func showPSA(shouldAddSafeAreaCoverView: Bool) {
        guard bottomOverlayManager?.contains(.psa) == true else { return }

        shouldAddSafeAreaCoverView ? addSafeAreaCoverView() : removeSafeAreaCoverView()

        updateOverlayLayout { [weak self] in
            self?.bottomOverlayManager?.setItemVisibility(
                for: .psa,
                hidden: false
            )
        }
    }
    
    func dismissPSA() {
        updateOverlayLayout { [weak self] in
            self?.removeSubviewFromOverlay(.psa)
            self?.removeSafeAreaCoverView()
        }
    }
    
    func isPSABannerHidden() -> Bool {
        bottomOverlayManager?.isItemHidden(.psa) ?? true
    }
    
    func currentPSAView() -> PSAView? {
        bottomOverlayManager?.view(for: .psa) as? PSAView
    }
    
    func updatePSABannerVisibility(for viewController: UIViewController) -> Bool {
        let psaHidden = isPSABannerHidden()

        if let presenter = viewController as? (any BottomOverlayPresenterProtocol) {
            let shouldAddSafeAreaCoverView = (presenter as? (any BottomSafeAreaOverlayCoverStatusProviderProtocol))?.shouldShowSafeAreaOverlayCover
            ?? tabBar.isHidden

            psaHidden ? showPSA(shouldAddSafeAreaCoverView: shouldAddSafeAreaCoverView) : refreshPresenterContentView(presenter)
            return true
        } else {
            if !isPSABannerHidden() {
                hidePSA()
            }
            return false
        }
    }

    private func refreshPresenterContentView(_ presenter: any BottomOverlayPresenterProtocol) {
        let containerHeight = currentContainerHeight()
        presenter.updateContentView(containerHeight)
    }
    
    func showPSAViewIfNeeded() {
        let viewModel = psaViewModel ?? makePSAViewModel()
        viewModel.dispatch(.showPSAViewIfNeeded)
    }
    
    func makePSAViewModel() -> PSAViewModel {
        let router = PSAViewRouter(tabBarController: self)
        let useCase = PSAUseCase(repo: PSARepository.newRepo)
        return PSAViewModel(router: router, useCase: useCase)
    }
}
