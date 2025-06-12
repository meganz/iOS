import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import UIKit

protocol MediaDiscoveryRouting: Routing {
    func showImportLocation(photos: [NodeEntity])
    func showShareLink(sender: UIBarButtonItem?)
    func showDownload(photos: [NodeEntity])
    func showOnboarding(linkOption: LinkOption, photos: [NodeEntity])
}

@objc final class MediaDiscoveryRouter: NSObject, MediaDiscoveryRouting {
    private weak var presenter: UIViewController?
    private weak var mediaDiscoveryViewController: MediaDiscoveryViewController?
    private let parentNode: MEGANode
    private let folderLink: String?
    
    private var isFolderLink: Bool {
        folderLink != nil
    }
    
    @objc init(viewController: UIViewController?, parentNode: MEGANode, folderLink: String? = nil) {
        self.presenter = viewController
        self.parentNode = parentNode
        self.folderLink = folderLink
        
        super.init()
    }
    
    func build() -> UIViewController {
        let parentNode = parentNode.toNodeEntity()
        let sdk = isFolderLink ? MEGASdk.sharedFolderLink : MEGASdk.shared
        let analyticsUseCase = MediaDiscoveryAnalyticsUseCase(repository: AnalyticsRepository.newRepo)
        let mediaDiscoveryUseCase = MediaDiscoveryUseCase(filesSearchRepository: FilesSearchRepository(sdk: sdk),
                                                          nodeUpdateRepository: NodeUpdateRepository.newRepo)
        let downloadFileRepository = DownloadFileRepository(sdk: MEGASdk.shared,
                                                            sharedFolderSdk: isFolderLink ? MEGASdk.sharedFolderLink : nil)
        let saveMediaUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: downloadFileRepository,
                                                        fileCacheRepository: FileCacheRepository.newRepo,
                                                        nodeRepository: NodeRepository.newRepo, 
                                                        chatNodeRepository: ChatNodeRepository.newRepo,
                                                        downloadChatRepository: DownloadChatRepository.newRepo)
        let viewModel = MediaDiscoveryViewModel(parentNode: parentNode,
                                                router: self,
                                                analyticsUseCase: analyticsUseCase,
                                                mediaDiscoveryUseCase: mediaDiscoveryUseCase,
                                                saveMediaUseCase: saveMediaUseCase,
                                                credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo))
        let vc = MediaDiscoveryViewController(viewModel: viewModel, folderName: parentNode.name,
                                              contentMode: isFolderLink ? .mediaDiscoveryFolderLink : .mediaDiscovery)
        mediaDiscoveryViewController = vc
        return vc
    }
    
    func start() {
        guard let presenter = presenter else {
            MEGALogDebug("Unable to start Media Discovery Screen as presented controller is nil")
            return
        }
        
        let nav = MEGANavigationController(rootViewController: build())
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true, completion: nil)
    }
    
    func showImportLocation(photos: [NodeEntity]) {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.selectedNodesArray = photos.toMEGANodes(in: isFolderLink ? MEGASdk.sharedFolderLink : MEGASdk.shared)
        browserVC.browserAction = isFolderLink ? .importFromFolderLink : .import
        
        mediaDiscoveryViewController?.present(navigationController, animated: true)
    }
    
    func showShareLink(sender: UIBarButtonItem?) {
        guard let folderLink else { return }
        let activityViewController = UIActivityViewController(activityItems: [folderLink], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        mediaDiscoveryViewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    func showDownload(photos: [NodeEntity]) {
        guard let mediaDiscoveryViewController else { return }
        let transfers = photos.map {
            CancellableTransfer(handle: $0.handle, name: nil, isFile: $0.isFile, type: .download)
        }
        CancellableTransferRouter(presenter: mediaDiscoveryViewController, transfers: transfers,
                                  transferType: .download, isFolderLink: isFolderLink).start()
    }
    
    func showOnboarding(linkOption: LinkOption, photos: [NodeEntity]) {
        guard photos.isNotEmpty else { return }
        MEGALinkManager.selectedOption = linkOption
        MEGALinkManager.nodesFromLinkToDownloadAfterLogin(nodes: photos)
        
        let onboardingVC = OnboardingViewController.instantiateOnboarding(with: .default)
        let navigation = MEGANavigationController(rootViewController: onboardingVC)
        navigation.addRightCancelButton()
        mediaDiscoveryViewController?.present(navigation, animated: true, completion: nil)
    }
}
