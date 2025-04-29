import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import UIKit

final class MiniPlayerViewRouter: NSObject, MiniPlayerViewRouting {
    private weak var presenter: UIViewController?
    private var configEntity: AudioPlayerConfigEntity
    private var folderSDKLogoutRequired: Bool = false
    
    init(configEntity: AudioPlayerConfigEntity, presenter: UIViewController) {
        self.configEntity = configEntity
        self.presenter = presenter
    }
    
    @objc func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(withIdentifier: "MiniPlayerViewControllerID") as! MiniPlayerViewController
                
        folderSDKLogoutRequired = configEntity.isFolderLink
        
        vc.viewModel = MiniPlayerViewModel(
            configEntity: configEntity,
            router: self,
            nodeInfoUseCase: NodeInfoUseCase(nodeInfoRepository: NodeInfoRepository()),
            streamingInfoUseCase: StreamingInfoUseCase(streamingInfoRepository: StreamingInfoRepository()),
            offlineInfoUseCase: configEntity.relatedFiles != nil ? OfflineFileInfoUseCase(offlineInfoRepository: OfflineInfoRepository()) : nil,
            playbackContinuationUseCase: DIContainer.playbackContinuationUseCase,
            audioPlayerUseCase: AudioPlayerUseCase(repository: AudioPlayerRepository.newRepo)
        )
        
        return vc
    }

    @objc func start() {
        configEntity.playerHandler.presentMiniPlayer(build())
    }
    
    @objc func updatePresenter(_ presenter: UIViewController) {
        self.presenter = presenter
    }
    
    func currentPresenter() -> UIViewController? {
        presenter
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
        
        if let visibleController = UIApplication.mainTabBarVisibleController(),
           visibleController.conforms(to: (any AudioPlayerPresenterProtocol).self) {
            updatePresenter(visibleController)
            return visibleController
        }
        return nil
    }
    
    // MARK: - UI Actions
    func dismiss() {
        configEntity.playerHandler.closePlayer()
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
