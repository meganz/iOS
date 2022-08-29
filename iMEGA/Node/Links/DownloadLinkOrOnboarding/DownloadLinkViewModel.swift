import MEGADomain

protocol DownloadLinkRouterProtocol {
    func downloadFileLink()
    func downloadFolderLinkNodes()
    func showOnboarding()
}

final class DownloadLinkViewModel {
    private let router: DownloadLinkRouterProtocol
    private let authUseCase: AuthUseCaseProtocol
    private let networkMonitorUseCase: NetworkMonitorUseCaseProtocol
    
    private let link: URL?
    private let isFolderLink: Bool
    private let nodes: [NodeEntity]?

    init(router: DownloadLinkRouterProtocol,
         authUseCase: AuthUseCaseProtocol,
         networkMonitorUseCase: NetworkMonitorUseCaseProtocol,
         link: URL,
         isFolderLink: Bool) {
        self.router = router
        self.authUseCase = authUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.link = link
        self.nodes = nil
        self.isFolderLink = isFolderLink
    }
    
    init(router: DownloadLinkRouterProtocol,
         authUseCase: AuthUseCaseProtocol,
         networkMonitorUseCase: NetworkMonitorUseCaseProtocol,
         nodes: [NodeEntity],
         isFolderLink: Bool) {
        self.router = router
        self.authUseCase = authUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.isFolderLink = isFolderLink
        self.link = nil
        self.nodes = nodes
    }
    
    func checkIfLinkCanBeDownloaded() {
        if networkMonitorUseCase.isConnected() {
            if authUseCase.sessionId() != nil {
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
}
