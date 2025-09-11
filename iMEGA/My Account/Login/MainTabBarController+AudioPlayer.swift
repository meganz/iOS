import MEGAAppPresentation

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    private var currentPresenter: (any AudioPlayerPresenterProtocol)? {
        guard let nav = selectedViewController as? UINavigationController,
              let controller = nav.viewControllers.last as? (any AudioPlayerPresenterProtocol) else { return nil }
        return controller
    }
    
    func presentMiniPlayer(_ viewController: UIViewController, height: CGFloat) {
        guard let miniPlayerView = viewController.view else { return }
        
        addSubviewToOverlay(
            miniPlayerView,
            type: .audioPlayer,
            priority: .high,
            height: height
        )
        
        adjustMiniPlayerDisplay()
    }
    
    private func adjustMiniPlayerDisplay() {
        let shouldShowMiniPlayer = currentPresenter != nil
        
        let shouldAddSafeAreaCoverView = (currentPresenter as? (any BottomSafeAreaOverlayCoverStatusProviderProtocol))?.shouldShowSafeAreaOverlayCover ?? tabBar.isHidden
        
        if shouldShowMiniPlayer {
            shouldAddSafeAreaCoverView ? addSafeAreaCoverView() : removeSafeAreaCoverView()
        }
        
        updateOverlayLayout { [weak self] in
            self?.shouldUpdateProgressViewLocation()
            self?.bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: !shouldShowMiniPlayer
            )
        }
    }
    
    func isMiniPlayerHidden() -> Bool {
        guard let bottomOverlayManager else { return true }
        return bottomOverlayManager.isItemHidden(.audioPlayer)
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
        guard currentPresenter != nil else { return }
        
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
        guard let currentPresenter else { return }
        
        let bottomContainerVisible = (bottomOverlayContainer?.frame.height ?? 0) != 0
        let playerAlive = AudioPlayerManager.shared.isPlayerAlive()
        let presenterUpdated = currentPresenter.hasUpdatedContentView()
        
        /// If the bottom container’s visibility or the presenter’s content state does not match the player’s state, update the presenter.
        if (playerAlive != bottomContainerVisible) || (playerAlive != presenterUpdated) {
            AudioPlayerManager.shared.updateMiniPlayerPresenter(currentPresenter)
            let newHeight = playerAlive ? (bottomOverlayContainer?.frame.height ?? 0) : 0
            currentPresenter.updateContentView(newHeight)
        }
    }
    
    @objc func registerMiniPlayerHandler() {
        AudioPlayerManager.shared.addMiniPlayerHandler(self)
    }
    
    @objc func unregisterMiniPlayerHandler() {
        AudioPlayerManager.shared.removeMiniPlayerHandler(self)
    }
    
    @objc func updateTransferWidgetBottomConstraint() -> Float {
        AudioPlayerManager.shared.isPlayerAlive() ? -120.0 : -60.0
    }
}
