import MEGADomain

@objc class MyBackupsOCWrapper: NSObject {
    let myBackupsUseCase = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
    
    @objc func isBackupNode(_ node: MEGANode) -> Bool {
        myBackupsUseCase.isBackupNode(node.toNodeEntity())
    }
    
    @objc func isMyBackupsRootNode(_ node: MEGANode) async -> Bool {
        await myBackupsUseCase.isMyBackupsRootNode(node.toNodeEntity())
    }
}
