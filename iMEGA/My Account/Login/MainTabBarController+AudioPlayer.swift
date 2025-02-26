import MEGADesignToken

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        Task { @MainActor in
            guard let miniPlayerView = viewController.view else { return }
            
            miniPlayerVC?.view.removeFromSuperview()
            addSubviewToOverlay(
                miniPlayerView,
                type: .audioPlayer,
                priority: .high,
                height: 60
            )
            miniPlayerVC = viewController
            
            tabBar.isHidden ? addSafeAreaCoverView() : removeSafeAreaCoverView()
            
            shouldUpdateProgressViewLocation()
            
            AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: false)
        }
    }
    
    private func addSafeAreaCoverView() {
        guard safeAreaCoverView == nil else { return }
        
        let coverView = UIView()
        coverView.backgroundColor = TokenColors.Background.surface1
        coverView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coverView)
        
        NSLayoutConstraint.activate([
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coverView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        safeAreaCoverView = coverView
    }
    
    private func removeSafeAreaCoverView() {
        guard safeAreaCoverView != nil else { return }
        
        safeAreaCoverView?.removeFromSuperview()
        safeAreaCoverView = nil
    }
    
    func showMiniPlayer() {
        Task { @MainActor in
            if let navController = selectedViewController as? UINavigationController,
               let lastController = navController.viewControllers.last,
               lastController.conforms(to: (any AudioPlayerPresenterProtocol).self) {
                AudioPlayerManager.shared.showMiniPlayer(in: self)
                
                self.bottomOverlayManager?.showItem(.audioPlayer)
                AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: false)
            }
        }
    }
    
    func hideMiniPlayer() {
        Task { @MainActor in
            self.bottomOverlayManager?.hideItem(.audioPlayer)
            AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: false)
            self.removeSafeAreaCoverView()
        }
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
        shouldUpdateProgressViewLocation()
        removeSafeAreaCoverView()
    }
    
    func resetMiniPlayerContainer() {
        Task { @MainActor in
            self.removeSubviewFromOverlay(.audioPlayer)
        }
    }
    
    func currentContainerHeight() async -> CGFloat {
        await Task { @MainActor in
            self.bottomOverlayContainer?.frame.height ?? 0
        }.value
    }
    
    @objc func refreshBottomConstraint() {
        guard let container = bottomOverlayContainer else { return }
        bottomContainerBottomConstraint?.constant = bottomConstant
        container.layoutIfNeeded()
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        shouldUpdateProgressViewLocation()
    }
}
