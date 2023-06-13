import MEGADomain

protocol DownloadLinkRouterProtocol {
    func downloadFileLink()
    func downloadFolderLinkNodes()
    func showOnboarding()
}

final class DownloadLinkViewModel {
    private let router: DownloadLinkRouterProtocol
    private let credentialUseCase: any CredentialUseCaseProtocol
    
    private let link: URL?
    private let isFolderLink: Bool
    private let nodes: [NodeEntity]?

    init(router: DownloadLinkRouterProtocol,
         credentialUseCase: any CredentialUseCaseProtocol,
         link: URL,
         isFolderLink: Bool) {
        self.router = router
        self.credentialUseCase = credentialUseCase
        self.link = link
        self.nodes = nil
        self.isFolderLink = isFolderLink
    }
    
    init(router: DownloadLinkRouterProtocol,
         credentialUseCase: any CredentialUseCaseProtocol,
         nodes: [NodeEntity],
         isFolderLink: Bool) {
        self.router = router
        self.credentialUseCase = credentialUseCase
        self.isFolderLink = isFolderLink
        self.link = nil
        self.nodes = nodes
    }
    
    func checkIfLinkCanBeDownloaded() {
        if credentialUseCase.hasSession() {
            if isFolderLink {
                router.downloadFolderLinkNodes()
            } else {
                router.downloadFileLink()
            }
        } else {
            if isFolderLink {
                guard let nodes = nodes else {
                    return
                }
                MEGALinkManager.selectedOption = .downloadFolderOrNodes
                MEGALinkManager.nodesFromLinkToDownloadAfterLogin(nodes: nodes)
            } else {
                guard let link = link else {
                    return
                }
                MEGALinkManager.selectedOption = .downloadNode
                MEGALinkManager.linkSavedString = link.absoluteString
            }
            
            router.showOnboarding()
        }
    }
}
