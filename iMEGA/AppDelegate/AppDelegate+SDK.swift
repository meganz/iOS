import ContentLibraries
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

extension AppDelegate {
    @objc func initializeCameraUploadsNode() {
        CameraUploadNodeAccess.shared.loadNode()
    }
    
    @objc func postNodeUpdatesNotifications(for nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        postFavouriteUpdatesNotification(for: nodes)
    }
    
    @objc func validateCameraUploadsRootFolderIfNeeded(_ nodeList: MEGANodeList) {
        Task {
            let updatedNodes = nodeList.toNodeEntities()
            let cameraUploadsUseCase = CameraUploadsUseCase(cameraUploadsRepository: CameraUploadsRepository.newRepo)
            let cameraUploadsNode = try await cameraUploadsUseCase.cameraUploadsNode()
            
            let isCURootFolderAffected = cameraUploadsRootFolderWasAffected(
                by: updatedNodes,
                cameraUploadsNode: cameraUploadsNode
            )
            
            if isCURootFolderAffected {
                await resetCameraUploadsRootFolderIfNoLongerWritable(cameraUploadsNode)
            }
        }
    }
    
    @objc func removeCachedFilesIfNeeded(for nodeList: MEGANodeList) {
        let removedNodes = nodeList.toNodeEntities().filter { $0.isRemoved }
        if removedNodes.isNotEmpty {
            let nodesRemovedUseCase = NodesRemovedUseCase(
                thumbnailRepository: ThumbnailRepository.newRepo,
                fileRepository: FileSystemRepository.sharedRepo,
                removedNodes: removedNodes
            )
            Task {
                await nodesRemovedUseCase.removeCachedFiles()
            }
        }
    }
    
    @objc func enableRequestStatusMonitor() {
        let useCase = RequestStatusMonitorUseCase(repo: RequestStatusMonitorRepository.newRepo)
        useCase.enableRequestStatusMonitor(true)
    }
    
    @objc func addCompletedTransfer(_ sdk: MEGASdk, transfer: MEGATransfer) {
        Task { @MainActor in
            await sdk.addCompletedTransfer(transfer)
        }
    }
    
    // MARK: - Private
    
    private func postFavouriteUpdatesNotification(for nodes: [MEGANode]) {
        let updatedNodes = nodes.modifiedFavourites().toNodeEntities()
        if !updatedNodes.isEmpty {
            NotificationCenter.default.post(name: .didPhotoFavouritesChange, object: updatedNodes)
        }
    }
    
    private func cameraUploadsRootFolderWasAffected(
        by updatedNodes: [NodeEntity],
        cameraUploadsNode: NodeEntity
    ) -> Bool {
        let updatedInShareNodes = updatedNodes.nodes(for: [.inShare])
        let removedNodes = updatedNodes.removedChangeTypeNodes()
        let relevantUpdatedNodes = updatedInShareNodes + removedNodes
        
        return relevantUpdatedNodes.contains { $0.handle == cameraUploadsNode.handle }
    }
    
    private func resetCameraUploadsRootFolderIfNoLongerWritable(_ cameraUploadsNode: NodeEntity) async {
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        let accessLevel = await nodeUseCase.nodeAccessLevelAsync(nodeHandle: cameraUploadsNode.handle)
        
        /// Resetting the target node of Camera Uploads causes a new one to be created the next time it is requested, either when a new photo needs to be synchronized
        /// or when the system performs a validation check.
        guard accessLevel.rawValue <= MEGAShareType.accessRead.rawValue else { return }
        
        CameraUploadNodeAccess.shared.resetTargetNode()
    }
}
