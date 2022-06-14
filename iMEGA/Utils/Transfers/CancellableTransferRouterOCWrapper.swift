
@objc final class CancellableTransferRouterOCWrapper: NSObject {
    @objc func downloadNodes(_ nodes: [MEGANode], presenter: UIViewController, isFolderLink: Bool = false) {
        CancellableTransferRouter(presenter: presenter, transfers: transferViewEntities(fromNodes: nodes), transferType: .download, isFolderLink: isFolderLink).start()
    }
    
    @objc func downloadChatNodes(_ nodes: [MEGANode], messageId: MEGAHandle, chatId: MEGAHandle, presenter: UIViewController) {
        CancellableTransferRouter(presenter: presenter, transfers: chatTransferViewEntities(fromNodes: nodes, messageId: messageId, chatId: chatId), transferType: .downloadChat, isFolderLink: false).start()
    }
    
    @objc func uploadFiles(_ transfers: [CancellableTransfer], presenter: UIViewController, type: CancellableTransferType) {
        let collisionEntities = transfers.map { NameCollisionEntity(parentHandle: $0.parentHandle, name: URL(fileURLWithPath: $0.path).lastPathComponent, isFile: $0.isFile, fileUrl: URL(fileURLWithPath: $0.path))}
        NameCollisionViewRouter(presenter: presenter, transfers: transfers, nodes: nil, collisions: collisionEntities, collisionType: .upload).start()
    }
    
    private func transferViewEntities(fromNodes nodes: [MEGANode]) -> [CancellableTransfer] {
        nodes.map { CancellableTransfer(handle: $0.handle, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
    }
    
    private func chatTransferViewEntities(fromNodes nodes: [MEGANode], messageId: MEGAHandle, chatId: MEGAHandle) -> [CancellableTransfer] {
        nodes.map { CancellableTransfer(handle: $0.handle, messageId: messageId, chatId: chatId, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .downloadChat) }
    }
}
