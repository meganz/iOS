import Foundation

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        view.addSubview(miniPlayerView)
        
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomViewBottomConstraint = miniPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBar.frame.size.height)
        bottomViewBottomConstraint?.isActive = true
        
        miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0).isActive = true
        miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0).isActive = true
        miniPlayerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        bottomView = miniPlayerView
        
        shouldUpdateProgressViewLocation()
    }
    
    func showMiniPlayer() {
        if let navController = selectedViewController as? UINavigationController, (navController.viewControllers.last?.conforms(to: AudioPlayerPresenterProtocol.self) ?? false) {
            if bottomView == nil {
                AudioPlayerManager.shared.showMiniPlayer()
            }
            
            DispatchQueue.main.async {
                self.bottomView?.isHidden = false
            }
        }
    }
    
    func hideMiniPlayer() {
        DispatchQueue.main.async {
            self.bottomView?.isHidden = true
        }
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
        shouldUpdateProgressViewLocation()
    }
    
    func resetMiniPlayerContainer() {
        DispatchQueue.main.async {
            self.bottomView?.removeFromSuperview()
            self.bottomView = nil
        }
    }
    
    @objc func refreshBottomConstraint() {
        guard bottomView != nil else { return }
        
        bottomViewBottomConstraint?.constant = -tabBar.frame.size.height
        bottomView?.layoutIfNeeded()
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        shouldUpdateProgressViewLocation()
    }
}
