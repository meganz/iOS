import MEGADomain

@objc class InboxUseCaseOCWrapper: NSObject {
    let inboxUseCase = InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo)
    
    @objc func isInboxNode(_ node: MEGANode) -> Bool {
        inboxUseCase.isInboxNode(node.toNodeEntity())
    }
    
    @objc func containsAnyInboxNode(_ nodes: [MEGANode]) -> Bool {
        inboxUseCase.containsAnyInboxNode(nodes.toNodeEntities())
    }
    
    func isInboxRootNode(_ node: MEGANode) -> Bool {
        inboxUseCase.isInboxRootNode(node.toNodeEntity())
    }
    
    func isBackupDeviceFolder(_ node: MEGANode) -> Bool {
        inboxUseCase.isBackupDeviceFolder(node.toNodeEntity())
    }
}
