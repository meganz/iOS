import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@MainActor
protocol ImportLinkRouting {
    func start()
    func showNodeBrowser()
    func showOnboarding()
}

@MainActor
final class ImportLinkViewModel {
    private let router: any ImportLinkRouting
    private let credentialUseCase: any CredentialUseCaseProtocol
    private let isFolderLink: Bool
    private let nodes: [MEGANode]
    
    init(router: some ImportLinkRouting,
         credentialUseCase: some CredentialUseCaseProtocol,
         isFolderLink: Bool,
         nodes: [MEGANode]) {
        self.router = router
        self.credentialUseCase = credentialUseCase
        self.isFolderLink = isFolderLink
        self.nodes = nodes
    }
    
    func importNodes() {
        guard nodes.isNotEmpty else { return }
        if credentialUseCase.hasSession() {
            router.showNodeBrowser()
        } else {
            MEGALinkManager.selectedOption = isFolderLink ? .importFolderOrNodes : .importNode
            MEGALinkManager.nodesFromLinkMutableArray.addObjects(from: nodes)
            
            router.showOnboarding()
        }
    }
}
