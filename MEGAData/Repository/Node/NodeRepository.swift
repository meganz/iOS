import MEGADomain

struct NodeRepository: NodeRepositoryProtocol {
    static var newRepo: NodeRepository {
        NodeRepository(sdk: MEGASdkManager.sharedMEGASdk(), sharedFolderSdk: MEGASdkManager.sharedMEGASdkFolder(), chatSdk: MEGASdkManager.sharedMEGAChatSdk())
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    private let chatSdk: MEGAChatSdk

    init(sdk: MEGASdk, sharedFolderSdk: MEGASdk, chatSdk: MEGAChatSdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.chatSdk = chatSdk
    }
    
    // MARK: - Node
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        if let node = sdk.node(forHandle: handle) {
            return node.toNodeEntity()
        } else if let node = sharedFolderSdk.node(forHandle: handle) {
            return node.toNodeEntity()
        }
        
        return nil
    }

    func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void) {
        sdk.publicNode(forMegaFileLink: fileLink.linkURL.absoluteString, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let node = request.publicNode else {
                    completion(.failure(.nodeNotFound))
                    return
                }
                completion(.success(node.toNodeEntity()))
            case .failure(_):
                completion(.failure(.nodeNotFound))
            }
        })
    }
    
    func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            nodeFor(fileLink: fileLink) { result in
                switch result {
                case .success(let node):
                    continuation.resume(returning: node)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity? {
        if let message = chatSdk.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), handle == node.handle {
            return node.toNodeEntity()
        } else if let messageForNodeHistory = chatSdk.messageFromNodeHistory(forChat: chatId, messageId: messageId), let node = messageForNodeHistory.nodeList?.node(at: 0), handle == node.handle {
            return node.toNodeEntity()
        } else {
            return nil
        }
    }
    
    func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        guard let parent = sdk.node(forHandle: parentHandle), let node = sdk.childNode(forParent: parent, name: name) else {
            return nil
        }
        
        return node.toNodeEntity()
    }
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        guard let parent = parentNode.toMEGANode(in: sdk) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    func images(for parentHandle: HandleEntity) -> [NodeEntity] {
        guard let parent = sdk.node(forHandle: parentHandle) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    func rubbishNode() -> NodeEntity? {
        MEGASdkManager.sharedMEGASdk().rubbishNode?.toNodeEntity()
    }
    
    // MARK: - Private
    private func images(forParentNode node: MEGANode) -> [NodeEntity] {
        let nodeList = sdk.children(forParent: node)
        let mediaNodes = (nodeList.mnz_mediaNodesMutableArrayFromNodeList() as? [MEGANode]) ?? []
        let imageNodes = mediaNodes.filter({ $0.name?.mnz_isImagePathExtension == true })
        
        return imageNodes.toNodeEntities()
    }
}
