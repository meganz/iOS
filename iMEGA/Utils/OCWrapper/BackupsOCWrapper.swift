import MEGAAppSDKRepo
import MEGADomain

@objc class BackupsOCWrapper: NSObject {
    let backupsUseCase = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo)
    
    @objc func isBackupNode(_ node: MEGANode) -> Bool {
        backupsUseCase.isBackupNode(node.toNodeEntity())
    }
    
    @objc func isBackupsRootNode(_ node: MEGANode) -> Bool {
        backupsUseCase.isBackupsRootNode(node.toNodeEntity())
    }
}
