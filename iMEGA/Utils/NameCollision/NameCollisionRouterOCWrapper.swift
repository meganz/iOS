import MEGADomain

@MainActor
@objc final class NameCollisionRouterOCWrapper: NSObject {
    @objc func uploadFiles(_ transfers: [CancellableTransfer], presenter: UIViewController, type: CancellableTransferType) {
        let collisionEntities = transfers.map { NameCollisionEntity(parentHandle: $0.parentHandle, name: $0.localFileURL?.lastPathComponent ?? "", isFile: $0.isFile, fileUrl: $0.localFileURL) }
        NameCollisionViewRouter(presenter: presenter, transfers: transfers, nodes: nil, collisions: collisionEntities, collisionType: .upload).start()
    }
    
    @objc func copyNodes(_ nodes: [MEGANode], to parent: MEGANode, isFolderLink: Bool = false, presenter: UIViewController) {
        let nodeEntities = nodes.toNodeEntities()
        let collisionEntities = nodeEntities.map { NameCollisionEntity(parentHandle: parent.handle, name: $0.name, isFile: $0.isFile, nodeHandle: $0.handle)}
        NameCollisionViewRouter(presenter: presenter, transfers: nil, nodes: nodeEntities, collisions: collisionEntities, collisionType: .copy, isFolderLink: isFolderLink).start()
    }
    
    @objc func moveNodes(_ nodes: [MEGANode], to parent: MEGANode, presenter: UIViewController) {
        let nodeEntities = nodes.toNodeEntities()
        let collisionEntities = nodeEntities.map { NameCollisionEntity(parentHandle: parent.handle, name: $0.name, isFile: $0.isFile, nodeHandle: $0.handle)}
        NameCollisionViewRouter(presenter: presenter, transfers: nil, nodes: nodeEntities, collisions: collisionEntities, collisionType: .move).start()
    }
}
