import Foundation
import MEGADesignToken

extension MainTabBarController: AudioMiniPlayerHandlerProtocol {
    var bottomConstant: CGFloat {
        tabBar.isHidden ? -view.safeAreaInsets.bottom : -tabBar.frame.size.height
    }
    
    func presentMiniPlayer(_ viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        tabBar.isHidden ? addSafeAreaCoverView() : removeSafeAreaCoverView()
        
        view.addSubview(miniPlayerView)
        layoutMiniPlayerView(miniPlayerView)
        bottomView = miniPlayerView
        
        shouldUpdateProgressViewLocation()
    }
    
    private func layoutMiniPlayerView(_ miniPlayerView: UIView) {
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomViewBottomConstraint = miniPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: bottomConstant)
        bottomViewBottomConstraint?.isActive = true
        
        [miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
         miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
         miniPlayerView.heightAnchor.constraint(equalToConstant: 60)].activate()
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
        DispatchQueue.main.async {
            self.bottomView?.removeFromSuperview()
            self.bottomView = nil
        }
    }
    
    @objc func refreshBottomConstraint() {
        guard bottomView != nil else { return }
        
        bottomViewBottomConstraint?.constant = bottomConstant
        bottomView?.layoutIfNeeded()
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        shouldUpdateProgressViewLocation()
    }
}
