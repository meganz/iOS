import Foundation

extension FolderLinkViewController: AudioMiniPlayerHandlerProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        view.addSubview(miniPlayerView)

        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            miniPlayerView.heightAnchor.constraint(equalToConstant: 60.0),
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        bottomView = miniPlayerView
    }
    
    func showMiniPlayer() {
        AudioPlayerManager.shared.showMiniPlayer()
        DispatchQueue.main.async {
            self.bottomView?.isHidden = false
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
    }
    
    func resetMiniPlayerContainer() {        
        DispatchQueue.main.async {
            self.bottomView?.removeFromSuperview()
            self.bottomView = nil
        }
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            showMiniPlayer()
        }
    }
}
