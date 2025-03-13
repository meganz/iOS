import MEGADomain
import MEGAL10n

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
            let message = Strings.Localizable.Nodes.Action.hideItems(successCount)
            router.showSnackBar(message: message)
        }
    }
    
    func unhide() async {
        let successCount = await nodeActionUseCase.unhide(nodes: nodes)
            .successfulCount()
        let message = Strings.Localizable.Nodes.Action.unhideItems(successCount)
        router.showSnackBar(message: message)
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
