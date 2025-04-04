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
        
        adjustMiniPlayerDisplay(isHidden: false)
    }
    
    private func adjustMiniPlayerDisplay(isHidden: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.bottomView?.isHidden = isHidden
        }, completion: { _ in
            self.refreshPresenterContentOffset(isHidden: isHidden)
        })
    }
    
    func showMiniPlayer() {
        AudioPlayerManager.shared.showMiniPlayer()
        adjustMiniPlayerDisplay(isHidden: false)
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
        bottomView?.removeFromSuperview()
        bottomView = nil
    }
    
    func refreshPresenterContentOffset(isHidden: Bool) {
        AudioPlayerManager.shared.refreshContentOffset(presenter: self, isHidden: isHidden)
    }
    
    func currentContainerHeight() -> CGFloat {
        bottomView?.frame.height ?? 0
    }
    
    @objc func shouldShowMiniPlayer() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            showMiniPlayer()
        }
    }
    
    func updateContentView(_ height: CGFloat) {
        currentContentInsetHeight = height
        
        refreshContentInset()
    }
    
    @objc func refreshContentInset() {
        if isListViewModeSelected() {
            flTableView?.tableView?.contentInset = .init(top: 0, left: 0, bottom: currentContentInsetHeight, right: 0)
        } else {
            flCollectionView?.collectionView?.contentInset = .init(top: 0, left: 0, bottom: currentContentInsetHeight, right: 0)
        }
    }
    
    func hasUpdatedContentView() -> Bool {
        currentContentInsetHeight != 0
    }
}
