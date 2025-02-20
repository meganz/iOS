import Foundation

extension FolderLinkViewController: AudioMiniPlayerHandlerProtocol, AudioPlayerPresenterProtocol {
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
        
        Task { @MainActor in
            AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: false)
        }
    }
    
    func showMiniPlayer() {
        AudioPlayerManager.shared.showMiniPlayer()
        Task { @MainActor in
            self.bottomView?.isHidden = false
        }
    }
    
    func hideMiniPlayer() {
        Task { @MainActor in
            self.bottomView?.isHidden = true
        }
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
    }
    
    func resetMiniPlayerContainer() {        
        Task { @MainActor in
            self.bottomView?.removeFromSuperview()
            self.bottomView = nil
        }
    }
    
    func currentContainerHeight() async -> CGFloat {
        await Task { @MainActor in
            self.bottomView?.frame.height ?? 0
        }.value
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            showMiniPlayer()
        }
    }
    
    func updateContentView(_ height: CGFloat) {
        Task { @MainActor in
            if isListViewModeSelected() {
                flTableView?.tableView?.contentInset = .init(top: 0, left: 0, bottom: height, right: 0)
            } else {
                flCollectionView?.collectionView?.contentInset = .init(top: 0, left: 0, bottom: height, right: 0)
            }
        }
    }
}
