import Foundation

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func initMiniPlayer(viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        addChild(viewController)
        view.addSubview(miniPlayerView)
        viewController.didMove(toParent: self)
        
        miniPlayerView.autoSetDimension(.height, toSize: 60.0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0)
   
        miniPlayerView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: tabBar.frame.size.height - view.safeAreaInsets.bottom)
        bottomView = miniPlayerView
        
        shouldUpdateProgressViewLocation()
    }
    
    func showMiniPlayer() {
        if let navController = selectedViewController as? UINavigationController, (navController.viewControllers.last?.conforms(to: AudioPlayerPresenterProtocol.self) ?? false) {
            if bottomView == nil {
                AudioPlayerManager.shared.showMiniPlayer()
            } else {
                bottomView?.isHidden = false
            }
        }
    }
    
    func hideMiniPlayer() {
        bottomView?.isHidden = true
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
        shouldUpdateProgressViewLocation()
    }
    
    func resetMiniPlayerContainer() {
        bottomView?.removeFromSuperview()
        bottomView = nil
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.resetMiniPlayerContainer()
            self.showMiniPlayer()
        })
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        shouldUpdateProgressViewLocation()
    }
}
