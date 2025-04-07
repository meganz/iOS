import MEGAAppPresentation
import MEGADesignToken

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        addSubviewToOverlay(
            miniPlayerView,
            type: .audioPlayer,
            priority: .high,
            height: 60
        )
        
        adjustMiniPlayerDisplay()
    }
    
    private func adjustMiniPlayerDisplay() {
        tabBar.isHidden ? addSafeAreaCoverView() : removeSafeAreaCoverView()
        
        UIView.animate(withDuration: 0.25, animations: {
            self.shouldUpdateProgressViewLocation()
            self.bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: false
            )
        }, completion: { _ in
            guard let presenter = (self.selectedViewController as? UINavigationController)?.viewControllers.last as? (any AudioPlayerPresenterProtocol) else { return }
            presenter.updateContentView(self.bottomOverlayContainer?.frame.height ?? 0)
        })
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
    
    func isMiniPlayerHidden() -> Bool {
        bottomOverlayManager?.isItemHidden(.audioPlayer) ?? true
    }
    
    func updateMiniPlayerVisibility(for viewController: UIViewController) {
        guard AudioPlayerManager.shared.isPlayerAlive() else {
            if let presenter = viewController as? (any AudioPlayerPresenterProtocol),
               presenter.hasUpdatedContentView() {
                /// If the mini-player was closed on a different screen while the audio player was active,
                /// any previously modified content inset may no longer be valid. This call forces a reset of the
                /// current view's content inset to ensure proper layout.
                presenter.updateContentView(0)
            }
            return
        }
        let miniPlayerHidden = isMiniPlayerHidden()
        
        if let presenter = viewController as? (any AudioPlayerPresenterProtocol) {
            AudioPlayerManager.shared.updateMiniPlayerPresenter(presenter)
            miniPlayerHidden ? showMiniPlayer() : presenter.updateContentView(bottomOverlayContainer?.frame.height ?? 0)
        } else if !miniPlayerHidden {
            hideMiniPlayer()
        }
    }
    
    func showMiniPlayer() {
        if let navController = selectedViewController as? UINavigationController,
           let lastController = navController.viewControllers.last,
           lastController.conforms(to: (any AudioPlayerPresenterProtocol).self) {
            bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: false
            )
            adjustMiniPlayerDisplay()
        }
    }
    
    func containsMiniPlayerInstance() -> Bool {
        guard let bottomOverlayManager, let bottomOverlayStack else { return false }
        let audioPlayerView = bottomOverlayManager.view(for: .audioPlayer)
        let stackContainsPlayer = bottomOverlayStack.subviews.contains(where: { $0 == audioPlayerView})
        return bottomOverlayManager.contains(.audioPlayer) && stackContainsPlayer
    }
    
    func refreshContentOffset(presenter: (any AudioPlayerPresenterProtocol), isHidden: Bool) {
        AudioPlayerManager.shared.refreshContentOffset(presenter: presenter, isHidden: isHidden)
    }
    
    func hideMiniPlayer() {
        bottomOverlayManager?.setItemVisibility(
            for: .audioPlayer,
            hidden: true
        )
        guard let presenter = (selectedViewController as? UINavigationController)?.viewControllers.last as? (any AudioPlayerPresenterProtocol) else { return }
        presenter.updateContentView(bottomOverlayContainer?.frame.height ?? 0)
        removeSafeAreaCoverView()
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
        shouldUpdateProgressViewLocation()
    }
    
    func resetMiniPlayerContainer() {
        removeSubviewFromOverlay(.audioPlayer)
    }
    
    func currentContainerHeight() -> CGFloat {
        bottomOverlayContainer?.frame.height ?? 0
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
    
    /// Refreshes the mini player’s visibility by ensuring that both the delegate and content view
    /// accurately reflect the current state of the audio player.
    /// If the audio player is alive, the bottom overlay container should be visible (i.e., its height non‑zero)
    /// and the presenter’s content view should be updated accordingly. If these conditions aren’t met, this
    /// function assigns the proper delegate and refreshes the content view’s height.
    @objc func refreshMiniPlayerVisibility() {
        guard let presenter = (selectedViewController as? UINavigationController)?.viewControllers.last as? (any AudioPlayerPresenterProtocol) else { return }
        
        let bottomContainerVisible = (bottomOverlayContainer?.frame.height ?? 0) != 0
        let playerAlive = AudioPlayerManager.shared.isPlayerAlive()
        let presenterUpdated = presenter.hasUpdatedContentView()
        
        /// If the bottom container’s visibility or the presenter’s content state does not match the player’s state, update the presenter.
        if (playerAlive != bottomContainerVisible) || (playerAlive != presenterUpdated) {
            AudioPlayerManager.shared.updateMiniPlayerPresenter(presenter)
            let newHeight = playerAlive ? (bottomOverlayContainer?.frame.height ?? 0) : 0
            presenter.updateContentView(newHeight)
        }
    }
}
