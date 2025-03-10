import MEGADesignToken

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        Task { @MainActor in
            guard let miniPlayerView = viewController.view else { return }
            
            addSubviewToOverlay(
                miniPlayerView,
                type: .audioPlayer,
                priority: .high,
                height: 60
            )
            
            adjustMiniPlayerDisplay()
        }
    }
    
    private func adjustMiniPlayerDisplay() {
        Task { @MainActor in
            tabBar.isHidden ? addSafeAreaCoverView() : removeSafeAreaCoverView()
            
            shouldUpdateProgressViewLocation()
            
            await bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: false
            )
            
            refreshPresenterContentOffset(isHidden: false)
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
    
    func isMiniPlayerHidden() -> Bool {
        bottomOverlayManager?.isItemHidden(.audioPlayer) ?? true
    }
    
    func updateMiniPlayerVisibility(for viewController: UIViewController) {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        let miniPlayerHidden = isMiniPlayerHidden()
        
        if let audioPlayerDelegate = viewController as? (any AudioPlayerPresenterProtocol) {
            AudioPlayerManager.shared.addDelegate(audioPlayerDelegate)
            miniPlayerHidden ? showMiniPlayer() : refreshPresenterContentOffset(isHidden: false)
        } else {
            !miniPlayerHidden ? hideMiniPlayer() : refreshPresenterContentOffset(isHidden: true)
        }
    }
    
    func showMiniPlayer() {
        Task { @MainActor in
            if let navController = selectedViewController as? UINavigationController,
               let lastController = navController.viewControllers.last,
               lastController.conforms(to: (any AudioPlayerPresenterProtocol).self) {
                await bottomOverlayManager?.setItemVisibility(
                    for: .audioPlayer,
                    hidden: false
                )
                adjustMiniPlayerDisplay()
            }
        }
    }
    
    func containsMiniPlayerInstance() -> Bool {
        guard let bottomOverlayManager, let bottomOverlayStack else { return false }
        let audioPlayerView = bottomOverlayManager.view(for: .audioPlayer)
        let stackContainsPlayer = bottomOverlayStack.subviews.contains(where: { $0 == audioPlayerView})
        return bottomOverlayManager.contains(.audioPlayer) && stackContainsPlayer
    }
    
    func refreshPresenterContentOffset(isHidden: Bool) {
        Task { @MainActor in
            AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: isHidden)
        }
    }
    
    func hideMiniPlayer() {
        Task { @MainActor in
            await bottomOverlayManager?.setItemVisibility(
                for: .audioPlayer,
                hidden: true
            )
            refreshPresenterContentOffset(isHidden: true)
            removeSafeAreaCoverView()
        }
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
        shouldUpdateProgressViewLocation()
    }
    
    func resetMiniPlayerContainer() {
        Task { @MainActor in
            removeSubviewFromOverlay(.audioPlayer)
        }
    }
    
    func currentContainerHeight() async -> CGFloat {
        await Task { @MainActor in
            bottomOverlayContainer?.frame.height ?? 0
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
    
    /// When changing the Audio player handler (e.g.: Opening the Audio Player via a folder link and then closing it to return to the app),
    /// the view displaying the player in the app might not have been previously added as a delegate. This could result in the content size not being updated.
    /// This function ensures that the appropriate delegate is added and the content offset is refreshed to avoid that issue.
    @objc func refreshMiniPlayerVisibility() {
        Task { @MainActor in
            if let navController = selectedViewController as? UINavigationController,
               let lastController = navController.viewControllers.last as? (any AudioPlayerPresenterProtocol) {
                
                let bottomContainerHeight = bottomOverlayContainer?.frame.height ?? 0
                let isPlayerAlive = AudioPlayerManager.shared.isPlayerAlive()
                
                if (bottomContainerHeight == 0 && isPlayerAlive) ||
                    (bottomContainerHeight != 0 && !isPlayerAlive) {
                    // The delegate is only being added if the AudioPlayerManager listeners array doesn't contains it
                    AudioPlayerManager.shared.addDelegate(lastController)
                    refreshPresenterContentOffset(isHidden: !isPlayerAlive)
                }
            }
        }
    }
}
