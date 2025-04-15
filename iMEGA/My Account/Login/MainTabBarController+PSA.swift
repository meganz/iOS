import MEGAAppPresentation

extension MainTabBarController {
    func presentPSA(_ psaView: UIView) {
        addSubviewToOverlay(
            psaView,
            type: .psa,
            priority: .normal
        )
        
        shouldUpdateProgressViewLocation()
        showPSA()
    }
    
    func hidePSA() {
        performAnimation { [weak self] in
            self?.bottomOverlayManager?.setItemVisibility(
                for: .psa,
                hidden: true
            )
        }
    }
    
    func showPSA() {
        tabBar.isHidden ? addSafeAreaCoverView() : removeSafeAreaCoverView()
        
        performAnimation { [weak self] in
            self?.bottomOverlayManager?.setItemVisibility(
                for: .psa,
                hidden: false
            )
        }
    }
    
    func dismissPSA() {
        performAnimation { [weak self] in
            self?.removeSubviewFromOverlay(.psa)
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
        
        if !viewController.hidesBottomBarWhenPushed, let presenter = viewController as? (any BottomOverlayPresenterProtocol) {
            psaHidden ? showPSA() : refreshPresenterContentView(presenter)
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
}
