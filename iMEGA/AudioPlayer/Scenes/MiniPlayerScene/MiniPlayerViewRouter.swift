import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import UIKit

@MainActor
final class MiniPlayerViewRouter: NSObject, MiniPlayerViewRouting {
    private weak var presenter: UIViewController?
    private var baseViewController: UIViewController?
    private var configEntity: AudioPlayerConfigEntity
    private var folderSDKLogoutRequired: Bool = false
    
    init(
        configEntity: AudioPlayerConfigEntity,
        presenter: UIViewController
    ) {
        self.configEntity = configEntity
        self.presenter = presenter
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] deallocating MiniPlayerViewRouter instance")
    }
    
    func build() -> UIViewController {
        let storyboard = UIStoryboard(name: "AudioPlayer", bundle: nil)
        guard let vc = storyboard.instantiateViewController(
            identifier: "MiniPlayerViewControllerID",
            creator: { coder in
                let viewModel = self.makeMiniPlayerViewModel()
                return MiniPlayerViewController(coder: coder, viewModel: viewModel)
            }
        ) as? MiniPlayerViewController else {
            return UIViewController()
        }
        
        self.baseViewController = vc
        return vc
    }
    
    private func makeMiniPlayerViewModel() -> MiniPlayerViewModel {
        folderSDKLogoutRequired = configEntity.isFolderLink
        
        return MiniPlayerViewModel(
            configEntity: configEntity,
            playerHandler: AudioPlayerManager.shared,
            router: self,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: NodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: StreamingInfoRepository()),
            offlineInfoUseCase: OfflineFileInfoUseCase(offlineInfoRepository: OfflineInfoRepository()),
            playbackContinuationUseCase: DIContainer.playbackContinuationUseCase,
            audioPlayerUseCase: AudioPlayerUseCase(repository: AudioPlayerRepository.newRepo)
        )
    }
    
    func start() {
        AudioPlayerManager.shared.presentMiniPlayer(build())
    }
    
    @objc func updatePresenter(_ presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func currentPresenter() -> UIViewController? {
        presenter
    }
    
    func currentMiniPlayerView() -> UIViewController? {
        baseViewController
    }
    
    func folderSDKLogout(required: Bool) {
        folderSDKLogoutRequired = required
    }
    
    func isFolderSDKLogoutRequired() -> Bool {
        folderSDKLogoutRequired && !isAFolderLinkPresenter()
    }
    
    func isAFolderLinkPresenter() -> Bool {
        presenter?.isKind(of: FolderLinkViewController.self) ?? false
    }
    
    func refresh(with newConfig: AudioPlayerConfigEntity) {
        configEntity = newConfig
        
        guard let miniVC = baseViewController as? MiniPlayerViewController else {
            start()
            return
        }
        
        miniVC.refreshPlayer(with: newConfig)
        
        AudioPlayerManager.shared.showMiniPlayer()
    }
    
    func showTermsOfServiceViolationAlert() {
        guard let baseViewController else { return }
        
        let alertController = UIAlertController(
            title: Strings.Localizable.General.Alert.TermsOfServiceViolation.title,
            message: Strings.Localizable.fileLinkUnavailableText2,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: Strings.Localizable.dismiss, style: .default, handler: { [weak self] _ in
            AudioPlayerManager.shared.closePlayer()
            self?.dismiss()
        }))
        
        baseViewController.present(alertController, animated: true)
    }
    
    /// Returns the active presenter that is currently visible in the view hierarchy.
    ///
    /// This method checks if the current presenter is visible (i.e., its view is loaded and attached to a window). If not, it attempts to retrieve a visible
    /// controller from the main tab bar that conforms to `AudioPlayerPresenterProtocol`, updating the presenter reference if a valid controller
    /// is found. With this function we try to avoid the issue that appears if the current presenter is not in the view hierarchy, and therefore the full-screen
    /// player cannot be displayed.
    ///
    /// - Returns:An Audio Player presenter that is currently visible, or `nil` if no appropriate presenter is found.
    private func activePresenter() -> UIViewController? {
        if let presenter, presenter.isViewLoaded && presenter.view.window != nil {
            return presenter
        }
        
        if let visibleController = UIApplication.mainTabBarVisibleController() as? (any AudioPlayerPresenterProtocol) {
            updatePresenter(visibleController)
            return visibleController
        }
        return nil
    }
    
    // MARK: - UI Actions
    func dismiss() {
        AudioPlayerManager.shared.closePlayer()
    }
    
    func showPlayer(node: MEGANode?, filePath: String?) {
        guard let currentPresenter = activePresenter() else { return }
        
        AudioPlayerManager.shared.initFullScreenPlayer(
            node: node,
            fileLink: filePath,
            filePaths: configEntity.relatedFiles,
            isFolderLink: configEntity.isFolderLink,
            presenter: currentPresenter,
            messageId: .invalid,
            chatId: .invalid,
            isFromSharedItem: configEntity.isFromSharedItem,
            allNodes: nil
        )
    }
}
