import Foundation
import MEGAAppPresentation

extension FolderLinkViewController: AudioMiniPlayerHandlerProtocol, AudioPlayerPresenterProtocol {
    func presentMiniPlayer(_ viewController: UIViewController, height: CGFloat) {
        guard let miniPlayerView = viewController.view else { return }
        
        bottomView?.removeFromSuperview()
        
        view.addSubview(miniPlayerView)
        
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            miniPlayerView.heightAnchor.constraint(equalToConstant: height),
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
            AudioPlayerManager.shared.showMiniPlayer()
        }
    }
    
    public func updateContentView(_ height: CGFloat) {
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
    
    public func hasUpdatedContentView() -> Bool {
        currentContentInsetHeight != 0
    }
    
    @objc func updateAudioPlayerVisibility(_ isHidden: Bool) {
        guard AudioPlayerManager.shared.isPlayerAlive() else { return }
        AudioPlayerManager.shared.playerHidden(isHidden, presenter: self)
    }
    
    @objc func registerMiniPlayerHandler() {
        AudioPlayerManager.shared.addMiniPlayerHandler(self)
    }
    
    @objc func unregisterMiniPlayerHandler() {
        AudioPlayerManager.shared.removeMiniPlayerHandler(self)
    }
    
    @objc func updateMiniPlayerPresenter() {
        AudioPlayerManager.shared.updateMiniPlayerPresenter(self)
    }
    
    @objc func logoutFolderLinkIfNoActivePlayer() {
        if !AudioPlayerManager.shared.isPlayerAlive() {
            MEGASdk.sharedFolderLink.logout()
        }
    }
}
