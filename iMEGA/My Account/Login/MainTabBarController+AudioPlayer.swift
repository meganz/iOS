import Foundation

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        view.addSubview(miniPlayerView)
        layoutMiniPlayerView(miniPlayerView)
        bottomView = miniPlayerView
        
        shouldUpdateProgressViewLocation()
    }
    
    private func layoutMiniPlayerView(_ miniPlayerView: UIView) {
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        let bottomConstant = -tabBar.frame.size.height
        bottomViewBottomConstraint = miniPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomConstant)
        bottomViewBottomConstraint?.isActive = true
        
        [miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         miniPlayerView.heightAnchor.constraint(equalToConstant: 60)].activate()
    }
    
    func showMiniPlayer() {
        if let navController = selectedViewController as? UINavigationController, 
            let lastController = navController.viewControllers.last,
            lastController.conforms(to: (any AudioPlayerPresenterProtocol).self) {
            AudioPlayerManager.shared.showMiniPlayer(in: self)
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
