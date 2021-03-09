import Foundation

extension FolderLinkViewController: AudioMiniPlayerHandlerProtocol {
    func initMiniPlayer(viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        addChild(viewController)
        view.addSubview(miniPlayerView)
        viewController.didMove(toParent: self)
        
        miniPlayerView.autoSetDimension(.height, toSize: 60.0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0)
        miniPlayerView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0)
        miniPlayerView.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: 0)
        
        bottomView = miniPlayerView
    }
    
    func showMiniPlayer() {
        if bottomView == nil {
            AudioPlayerManager.shared.showMiniPlayer()
        }
        
        bottomView?.isHidden = false
    }
    
    func hideMiniPlayer() {
        bottomView?.isHidden = true
    }
    
    func closeMiniPlayer() {
        bottomView?.isHidden = true
        resetMiniPlayerContainer()
    }
    
    func resetMiniPlayerContainer() {
        bottomView?.removeFromSuperview()
        bottomView = nil
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            showMiniPlayer()
        }
    }
}
