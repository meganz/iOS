import MEGAAppPresentation

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
        
        updateOverlayLayout { [weak self] in
            self?.shouldUpdateProgressViewLocation()
            self?.bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: false
            )
        }
    }
    
    func isMiniPlayerHidden() -> Bool {
        bottomOverlayManager?.isItemHidden(.audioPlayer) ?? true
    }
    
    func updateMiniPlayerVisibility(for viewController: UIViewController) -> Bool {
        guard AudioPlayerManager.shared.isPlayerAlive() else {
            if let presenter = viewController as? (any AudioPlayerPresenterProtocol),
               presenter.hasUpdatedContentView() {
                /// If the mini-player was closed on a different screen while the audio player was active,
                /// any previously modified content inset may no longer be valid. This call forces a reset of the
                /// current view's content inset to ensure proper layout.
                presenter.updateContentView(0)
            }
            return false
        }
        let miniPlayerHidden = isMiniPlayerHidden()
        
        if let presenter = viewController as? (any AudioPlayerPresenterProtocol) {
            AudioPlayerManager.shared.updateMiniPlayerPresenter(presenter)
            miniPlayerHidden ? showMiniPlayer() : presenter.updateContentView(bottomOverlayContainer?.frame.height ?? 0)
            return true
        } else if !miniPlayerHidden {
            hideMiniPlayer()
        }
        return false
    }
    
    func showMiniPlayer() {
        guard let navController = selectedViewController as? UINavigationController,
              let lastController = navController.viewControllers.last,
              lastController.conforms(to: (any AudioPlayerPresenterProtocol).self) else { return }
        
        if let bottomOverlayManager, bottomOverlayManager.contains(.audioPlayer) {
            bottomOverlayManager.setItemVisibility(for: .audioPlayer, hidden: false)
            adjustMiniPlayerDisplay()
        } else {
            shouldShowMiniPlayer()
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
        updateOverlayLayout { [weak self] in
            self?.bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: true
            )
        }
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
