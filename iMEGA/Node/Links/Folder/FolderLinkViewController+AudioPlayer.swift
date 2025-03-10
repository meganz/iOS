import Foundation

extension FolderLinkViewController: AudioMiniPlayerHandlerProtocol, AudioPlayerPresenterProtocol {
    func presentMiniPlayer(_ viewController: UIViewController) {
        Task { @MainActor in
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
            
            adjustMiniPlayerDisplay(isHidden: false)
        }
    }
    
    private func adjustMiniPlayerDisplay(isHidden: Bool) {
        Task { @MainActor in
            bottomView?.isHidden = isHidden
            refreshPresenterContentOffset(isHidden: isHidden)
        }
    }
    
    func showMiniPlayer() {
        Task { @MainActor in
            AudioPlayerManager.shared.showMiniPlayer()
            adjustMiniPlayerDisplay(isHidden: false)
        }
    }
    
    func hideMiniPlayer() {
        adjustMiniPlayerDisplay(isHidden: true)
    }
    
    func containsMiniPlayerInstance() -> Bool {
        bottomView?.subviews.first != nil
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
    }
    
    func resetMiniPlayerContainer() {        
        Task { @MainActor in
            bottomView?.removeFromSuperview()
            bottomView = nil
        }
    }
    
    func refreshPresenterContentOffset(isHidden: Bool) {
        Task { @MainActor in
            AudioPlayerManager.shared.refreshPresentersContentOffset(isHidden: isHidden)
        }
    }
    
    func currentContainerHeight() async -> CGFloat {
        await Task { @MainActor in
            bottomView?.frame.height ?? 0
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
