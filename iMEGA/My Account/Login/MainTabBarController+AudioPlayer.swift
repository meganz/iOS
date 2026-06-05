import MEGAAppPresentation
import MEGAAudioPlayer

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
        
        let safeAreaOverlayCoverAllowedForCurrentPresenter = if #available(iOS 26.0, *), let presenter = currentPresenter, isTabRoot(presenter) {
            false
        } else { true }
        let safeAreaOverlayCoverAllowed = tabBar.isHidden && safeAreaOverlayCoverAllowedForCurrentPresenter
        let shouldAddSafeAreaCoverView = (currentPresenter as? (any BottomSafeAreaOverlayCoverStatusProviderProtocol))?.shouldShowSafeAreaOverlayCover ?? safeAreaOverlayCoverAllowed
        
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
        if isAudioPlayerRevampEnabled {
            return updateRevampedMiniPlayerInset(for: viewController)
        }
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
        guard !isAudioPlayerRevampEnabled else { return }
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
        guard !isAudioPlayerRevampEnabled else { return }
        AudioPlayerManager.shared.addMiniPlayerHandler(self)
    }
    
    @objc func unregisterMiniPlayerHandler() {
        guard !isAudioPlayerRevampEnabled else { return }
        AudioPlayerManager.shared.removeMiniPlayerHandler(self)
    }

    private var isAudioPlayerRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .audioPlayerRevamp)
    }

    private func updateRevampedMiniPlayerInset(for viewController: UIViewController) -> Bool {
        let miniPlayerVisible = bottomOverlayManager?.contains(.audioPlayer) == true && !isMiniPlayerHidden()
        guard let presenter = viewController as? (any BottomOverlayPresenterProtocol) else { return miniPlayerVisible }
        if miniPlayerVisible {
            presenter.updateContentView(bottomOverlayContainer?.frame.height ?? 0)
        } else if presenter.hasUpdatedContentView() {
            presenter.updateContentView(0)
        }
        return miniPlayerVisible
    }
    
    @objc func updateTransferWidgetBottomConstraint() -> Float {
        AudioPlayerManager.shared.isPlayerAlive() ? -120.0 : -60.0
    }
    
    func isTabRoot(_ viewController: UIViewController) -> Bool {
        guard let viewControllers else { return false }
        if viewControllers.contains(viewController) { return true }
        guard let navigationVC = viewController.navigationController else { return false }
        return navigationVC.viewControllers.first === viewController && viewControllers.contains(navigationVC)
    }
}

// MARK: - Revamped mini player (audioPlayerRevamp)

extension MainTabBarController {
    @objc func setupRevampedMiniPlayerIfNeeded() {
        guard isAudioPlayerRevampEnabled, miniPlayerOverlayCoordinator == nil else { return }

        let coordinator = MEGAMiniPlayerOverlayCoordinator()

        coordinator.onAttach = { [weak self] hostViewController, height in
            guard let self, let pill = hostViewController.view else { return }
            addChild(hostViewController)
            updateOverlayLayout { [weak self] in
                self?.addSubviewToOverlay(pill, type: .audioPlayer, priority: .high, height: height)
            }
            hostViewController.didMove(toParent: self)
        }

        coordinator.onDetach = { [weak self] hostViewController in
            guard let self else { return }
            hostViewController.willMove(toParent: nil)
            updateOverlayLayout { [weak self] in
                self?.removeSubviewFromOverlay(.audioPlayer)
            }
            hostViewController.removeFromParent()
        }

        coordinator.onExpand = { [weak self] in
            guard let self else { return }
            MEGAAudioPlayerViewRouter(
                presenter: self,
                actionsHandler: MEGAAudioPlayerActionsHandler.make(),
                navigationFactory: MEGAAudioPlayerNavigationController.make()
            ).showCurrent()
        }

        coordinator.startObserving()
        miniPlayerOverlayCoordinator = coordinator
    }
}
