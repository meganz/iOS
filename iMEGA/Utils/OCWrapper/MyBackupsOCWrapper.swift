import MEGADomain

@objc class MyBackupsOCWrapper: NSObject {
    let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
    
    @objc func isBackupNode(_ node: MEGANode) async -> Bool {
        await myBackupsUseCase.isBackupNode(node.toNodeEntity())
    }
}
