import Foundation

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func initMiniPlayer(viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        view.addSubview(miniPlayerView)
        
        miniPlayerView.autoSetDimension(.height, toSize: 60.0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0)
   
        miniPlayerView.autoPinEdge(.bottom, to: .top, of: tabBar)
        
        bottomView = miniPlayerView
        
        shouldUpdateProgressViewLocation()
    }
    
    func showMiniPlayer() {
        if let navController = selectedViewController as? UINavigationController, (navController.viewControllers.last?.conforms(to: AudioPlayerPresenterProtocol.self) ?? false) {
            if bottomView == nil {
                AudioPlayerManager.shared.showMiniPlayer()
            }
            
            bottomView?.isHidden = false
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
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        shouldUpdateProgressViewLocation()
    }
}
