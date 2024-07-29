import MEGADomain

final class NodeDescriptionViewModel {
    let node: NodeEntity
    let nodeUseCase: any NodeUseCaseProtocol
    let backupUseCase: any BackupsUseCaseProtocol

    var hasReadOnlyAccess: Bool {
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)

        return nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
        || backupUseCase.isBackupNodeHandle(node.handle)
        || backupUseCase.isBackupsRootNode(node)
        || (nodeAccessLevel != .full && nodeAccessLevel != .owner)
    }

    init(
        node: NodeEntity,
        nodeUseCase: some NodeUseCaseProtocol,
        backupUseCase: some BackupsUseCaseProtocol
    ) {
        self.node = node
        self.nodeUseCase = nodeUseCase
        self.backupUseCase = backupUseCase
    }
}
