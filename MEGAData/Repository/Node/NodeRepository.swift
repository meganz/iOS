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
    
    func nodeAccessLevel(nodeHandle: MEGAHandle) -> NodeAccessTypeEntity {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return .unknown
        }
        return NodeAccessTypeEntity(shareAccess: sdk.accessLevel(for: node)) ?? .unknown
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        let nodeLabel = MEGANodeLabel(nodeLabelTypeEntity: label) ?? .unknown
        return MEGANode.string(for: nodeLabel) ?? "" + "Small"
    }
    
    func getFilesAndFolders(nodeHandle: MEGAHandle) -> (childFileCount: Int, childFolderCount: Int) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return (0, 0)
        }
        
        let numberOfFiles = sdk.numberChildFiles(forParent: node)
        let numberOfFolders = sdk.numberChildFolders(forParent: node)
        
        return (numberOfFiles, numberOfFolders)
    }
    
    func hasVersions(nodeHandle: MEGAHandle) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.hasVersions(for: node)
    }
    
    func isDownloaded(nodeHandle: MEGAHandle) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return (MEGAStore.shareInstance().offlineNode(with: node) != nil)
    }
    
    func isInRubbishBin(nodeHandle: MEGAHandle) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.isNode(inRubbish: node)
    }
    
    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.toNodeEntity()
    }

    func nameForNode(handle: MEGAHandle) -> String? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.name
    }
    
    func nameForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String? {
        chatNode(handle: handle, messageId: messageId, chatId: chatId)?.name
    }
    
    func nodeNameFor(fileLink: FileLinkEntity) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            sdk.publicNode(forMegaFileLink: fileLink.linkURLString, delegate: RequestDelegate { (result) in
                switch result {
                case .success(let request):
                    guard let name = request.publicNode.name else {
                        continuation.resume(throwing: NodeErrorEntity.nodeNameNotFound)
                        return
                    }
                    continuation.resume(returning: name)
                case .failure(_):
                    continuation.resume(throwing: NodeErrorEntity.nodeNotFound)
                }
            })
        }
    }
    
    func sizeForNode(handle: MEGAHandle) -> UInt64? {
        var megaNode: MEGANode
        if let node = sdk.node(forHandle: handle) {
            megaNode = node
        } else if let node = sharedFolderSdk.node(forHandle: handle) {
            megaNode = node
        } else {
            return nil
        }
        
        if megaNode.isFile() {
            return megaNode.size?.uint64Value
        } else {
            return sdk.size(for: megaNode).uint64Value
        }
    }
    
    func sizeForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> UInt64? {
        chatNode(handle: handle, messageId: messageId, chatId: chatId)?.size?.uint64Value
    }
    
    func base64ForNode(handle: MEGAHandle) -> String? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.base64Handle
    }
    
    func base64ForChatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> String? {
        chatNode(handle: handle, messageId: messageId, chatId: chatId)?.base64Handle
    }
    
    private func chatNode(handle: MEGAHandle, messageId: MEGAHandle, chatId: MEGAHandle) -> MEGANode? {
        guard let message = chatSdk.message(forChat: chatId, messageId: messageId), let node = message.nodeList?.node(at: 0), handle == node.handle else {
            return nil
        }
        
        return node
    }
    
    func isFileNode(handle: MEGAHandle) -> Bool {
        guard let node = sdk.node(forHandle: handle) else {
            return false
        }
        
        return node.isFile()
    }
    
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle, newName: String?) -> Bool {
        guard let fileFingerprint = sdk.fingerprint(forFilePath: path),
              let parentNode = sdk.node(forHandle: parentHandle),
              let node = sdk.node(forFingerprint: fileFingerprint) else {
            return false
        }
        
        if node.parentHandle != parentHandle {
            if let newName = newName {
                sdk.copy(node, newParent: parentNode, newName: newName)
            } else {
                sdk.copy(node, newParent: parentNode)
            }
        }
        
        return true
    }
    
    func copyNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?, isFolderLink: Bool) async throws -> NodeHandle {
        try await withCheckedThrowingContinuation { continuation in
            var megaNode: MEGANode
            guard let parentNode = sdk.node(forHandle: parentHandle) else {
                continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                return
            }
            
            if isFolderLink {
                guard let linkNode = sharedFolderSdk.node(forHandle: handle), let authorizedNode = sharedFolderSdk.authorizeNode(linkNode) else {
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeAuthorizeFailed)
                    return
                }
                megaNode = authorizedNode
            } else {
                guard let node = sdk.node(forHandle: handle) else {
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                    return
                }
                megaNode = node
            }
            
            let delegate = RequestDelegate { result in
                switch result {
                case .failure(_):
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeCopyFailed)
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                }
            }
            if let newName = newName {
                sdk.copy(megaNode, newParent: parentNode, newName: newName, delegate: delegate)
            } else {
                sdk.copy(megaNode, newParent: parentNode, delegate: delegate)
            }
        }
    }
    
    func moveNode(handle: NodeHandle, in parentHandle: NodeHandle, newName: String?) async throws -> NodeHandle {
        try await withCheckedThrowingContinuation { continuation in
            guard let parentNode = sdk.node(forHandle: parentHandle),
                  let node = sdk.node(forHandle: handle) else {
                continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                return
            }
                        
            let delegate = RequestDelegate { result in
                switch result {
                case .failure(_):
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeCopyFailed)
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                }
            }
            if let newName = newName {
                sdk.move(node, newParent: parentNode, newName: newName, delegate: delegate)
            } else {
                sdk.move(node, newParent: parentNode, delegate: delegate)
            }
        }
    }

    
    func fingerprintForFile(at path: String) -> String? {
        sdk.fingerprint(forFilePath: path)
    }
    
    func setNodeCoordinates(nodeHandle: MEGAHandle, latitude: Double, longitude: Double) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return
        }
        if node.latitude != nil && node.longitude != nil {
            return
        }
        sdk.setNodeCoordinates(node, latitude: latitude as NSNumber, longitude: longitude as NSNumber)
    }
    
    func childNodeNamed(name: String, in parentHandle: MEGAHandle) -> NodeEntity? {
        guard let parent = sdk.node(forHandle: parentHandle), let node = sdk.childNode(forParent: parent, name: name) else {
            return nil
        }
        
        return node.toNodeEntity()
    }

    func creationDateForNode(handle: MEGAHandle) -> Date? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.creationTime
    }
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        guard let parent = parentNode.toMEGANode(in: sdk) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    func images(for parentHandle: MEGAHandle) -> [NodeEntity] {
        guard let parent = sdk.node(forHandle: parentHandle) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    // MARK: - Private
    
    private func images(forParentNode node: MEGANode) -> [NodeEntity] {
        let nodeList = sdk.children(forParent: node)
        let mediaNodes = (nodeList.mnz_mediaNodesMutableArrayFromNodeList() as? [MEGANode]) ?? []
        let imageNodes = mediaNodes.filter({ $0.name?.mnz_isImagePathExtension == true })
        
        return imageNodes.toNodeEntities()
    }
}
