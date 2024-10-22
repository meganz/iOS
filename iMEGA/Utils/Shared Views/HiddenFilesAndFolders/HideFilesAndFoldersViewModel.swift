import MEGADomain

@MainActor
final class HideFilesAndFoldersViewModel {
    private let router: any HideFilesAndFoldersRouting
    private let nodes: [NodeEntity]
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let nodeActionUseCase: any NodeActionUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    
    init(
        nodes: [NodeEntity],
        router: some HideFilesAndFoldersRouting,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeActionUseCase: some NodeActionUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol
    ) {
        self.nodes = nodes
        self.router = router
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeActionUseCase = nodeActionUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
    }
    
    func hide() async {
        if !sensitiveNodeUseCase.isAccessible() {
            router.showSeeUpgradePlansOnboarding()
        } else if await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().onboarded {
            router.showFirstTimeOnboarding(nodes: nodes)
        } else {
            let successCount = await nodeActionUseCase.hide(nodes: nodes)
                .successfulCount()
            router.showItemsHiddenSuccessfully(count: successCount)
        }
    }
}

private extension Dictionary where Key == HandleEntity, Value == Result<NodeEntity, any Error> {
    func successfulCount() async -> Int {
        filter { (nodeHandle, result) in
            switch result {
            case .success: return true
            case .failure(let error):
                MEGALogError("[\(type(of: self))] error \(error.localizedDescription) hiding node \(nodeHandle)")
                return false
            }
        }.count
    }
}
