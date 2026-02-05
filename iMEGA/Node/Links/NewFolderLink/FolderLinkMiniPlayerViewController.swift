import SwiftUI
import UIKit

final class FolderLinkMiniPlayerViewController: UIViewController, AudioMiniPlayerHandlerProtocol {
    private var miniPlayerViewController: UIViewController?
    @Binding var miniPlayerHeight: CGFloat
    @Binding var showing: Bool
    
    init(showing: Binding<Bool>, miniPlayerHeight: Binding<CGFloat>) {
        self._showing = showing
        self._miniPlayerHeight = miniPlayerHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AudioPlayerManager.shared.addMiniPlayerHandler(self)
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.showMiniPlayer()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerManager.shared.removeMiniPlayerHandler(self)
    }
    
    // MARK: - AudioMiniPlayerHandlerProtocol
    func presentMiniPlayer(_ viewController: UIViewController, height: CGFloat) {
        miniPlayerHeight = height
        resetMiniPlayerContainer()
        attach(miniPlayerViewController: viewController)
        adjustMiniPlayerDisplay(isHidden: false)
    }
    
    func showMiniPlayer() {
        adjustMiniPlayerDisplay(isHidden: false)
    }
    
    func hideMiniPlayer() {
        adjustMiniPlayerDisplay(isHidden: true)
    }
    
    func closeMiniPlayer() {
        hideMiniPlayer()
        resetMiniPlayerContainer()
    }
    
    func resetMiniPlayerContainer() {
        guard let miniPlayerViewController else { return }
        miniPlayerViewController.willMove(toParent: nil)
        miniPlayerViewController.view.removeFromSuperview()
        miniPlayerViewController.removeFromParent()
        self.miniPlayerViewController = nil
    }
    
    func currentContainerHeight() -> CGFloat {
        miniPlayerHeight
    }
    
    func containsMiniPlayerInstance() -> Bool {
        miniPlayerViewController != nil
    }
    
    // MARK: - Privates
    private func attach(miniPlayerViewController: UIViewController) {
        self.miniPlayerViewController = miniPlayerViewController
        addChild(miniPlayerViewController)
        let miniPlayerView: UIView = miniPlayerViewController.view
        miniPlayerView.isHidden = false
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(miniPlayerView)
        NSLayoutConstraint.activate([
            miniPlayerView.heightAnchor.constraint(equalToConstant: miniPlayerHeight),
            miniPlayerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            miniPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        miniPlayerViewController.didMove(toParent: self)
    }
    
    private func adjustMiniPlayerDisplay(isHidden: Bool) {
        self.showing = !isHidden
    }
}
