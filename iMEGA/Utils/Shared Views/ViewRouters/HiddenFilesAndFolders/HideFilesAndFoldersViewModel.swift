import MEGADomain

protocol HideFilesAndFoldersRouting {
    func hideNodes(_ nodes: [NodeEntity])
    func showHiddenFilesAndFoldersOnboarding()
    func showItemsHiddenSuccessfully(count: Int)
}

final class HideFilesAndFoldersViewModel {
    private let router: any HideFilesAndFoldersRouting
    private let nodes: [NodeEntity]
    private let accountUseCase: any AccountUseCaseProtocol
    private let nodeActionUseCase: any NodeActionUseCaseProtocol
    
    init(nodes: [NodeEntity],
         router: some HideFilesAndFoldersRouting,
         accountUseCase: some AccountUseCaseProtocol,
         nodeActionUseCase: some NodeActionUseCaseProtocol
    ) {
        self.nodes = nodes
        self.router = router
        self.accountUseCase = accountUseCase
        self.nodeActionUseCase = nodeActionUseCase
    }
    
    @MainActor
    func hideNodes() async {
        guard accountUseCase.currentAccountDetails?.proLevel != .free else {
            router.showHiddenFilesAndFoldersOnboarding()
            return
        }
        let successCount = await nodeActionUseCase.hide(nodes: nodes)
            .filter { (nodeHandle, result) in
                switch result {
                case .success: return true
                case .failure(let error):
                    MEGALogError("[HideFilesAndFoldersViewModel] error \(error.localizedDescription) hiding node \(nodeHandle)")
                    return false
                }
            }.count
        
        router.showItemsHiddenSuccessfully(count: successCount)
    }
}
