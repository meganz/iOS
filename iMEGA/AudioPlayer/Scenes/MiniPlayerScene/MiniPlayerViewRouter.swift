import Foundation
import UIKit

final class MiniPlayerViewRouter: NSObject, MiniPlayerViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private var playerHandler: AudioPlayerHandlerProtocol
    private var fileLink: String?
    private var isFolderLink: Bool?
    private var filePaths: [String]?
    private var node: MEGANode?
    private var shouldInitializePlayer: Bool = false
    private var folderSDKLogoutRequired: Bool = false
    
    @objc convenience init(node: MEGANode?, fileLink: String?, relatedFiles: [String]?, isFolderLink: Bool, presenter: UIViewController, playerHandler: AudioPlayerHandlerProtocol) {
        self.init(fileLink: fileLink, relatedFiles: relatedFiles, isFolderLink: isFolderLink, presenter: presenter, playerHandler: playerHandler)
        self.node = node
        self.shouldInitializePlayer = true
    }
    
    @objc init(fileLink: String?, relatedFiles: [String]?, isFolderLink: Bool, presenter: UIViewController, playerHandler: AudioPlayerHandlerProtocol) {
        self.fileLink = fileLink
        self.filePaths = relatedFiles
        self.isFolderLink = isFolderLink
        self.presenter = presenter
        self.playerHandler = playerHandler
    }
    
    @objc func build() -> UIViewController {
        let vc = UIStoryboard(name: "AudioPlayer", bundle: nil).instantiateViewController(withIdentifier: "MiniPlayerViewControllerID") as! MiniPlayerViewController
        
        folderSDKLogoutRequired = isFolderLink ?? false
    
        if shouldInitializePlayer {
            vc.viewModel = MiniPlayerViewModel(node: node,
                                               fileLink: fileLink,
                                               filePaths: filePaths,
                                               isFolderLink: isFolderLink ?? false,
                                               router: self,
                                               playerHandler: playerHandler,
                                               nodeInfoUseCase: NodeInfoUseCase(),
                                               streamingInfoUseCase: StreamingInfoUseCase(),
                                               offlineInfoUseCase: filePaths != nil ? OfflineFileInfoUseCase() : nil)
        } else {
            vc.viewModel = MiniPlayerViewModel(fileLink: fileLink,
                                               filePaths: filePaths,
                                               isFolderLink: isFolderLink ?? false,
                                               router: self,
                                               playerHandler: playerHandler,
                                               nodeInfoUseCase: NodeInfoUseCase(),
                                               streamingInfoUseCase: StreamingInfoUseCase(),
                                               offlineInfoUseCase: filePaths != nil ? OfflineFileInfoUseCase() : nil)
        }
        
        baseViewController = vc
        
        return vc
    }

    @objc func start() {
        playerHandler.presentMiniPlayer(build())
    }
    
    @objc func updatePresenter(_ presenter: UIViewController) {
        self.presenter = presenter
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
    
    // MARK: - UI Actions
    func dismiss() {
        playerHandler.closePlayer()
    }
    
    func showPlayer(node: MEGANode?, filePath: String?) {
        guard let presenter = presenter else { return }
        
        AudioPlayerManager.shared.initFullScreenPlayer(node: node, fileLink: node == nil ? filePath: nil, filePaths: filePaths, isFolderLink: isFolderLink ?? false, presenter: presenter)
    }
}
