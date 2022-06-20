
extension NodeRepository {
    static let `default` = NodeRepository(sdk: MEGASdkManager.sharedMEGASdk(), sharedFolderSdk: MEGASdkManager.sharedMEGASdkFolder(), chatSdk: MEGASdkManager.sharedMEGAChatSdk())
}

struct NodeRepository: NodeRepositoryProtocol {
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    private let chatSdk: MEGAChatSdk

    init(sdk: MEGASdk, sharedFolderSdk: MEGASdk, chatSdk: MEGAChatSdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.chatSdk = chatSdk
    }
    
    func nodeForHandle(_ handle: MEGAHandle) -> NodeEntity? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return NodeEntity(node: node)
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
    
    func sizeForNode(handle: MEGAHandle) -> UInt64? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        if node.isFile() {
            return node.size?.uint64Value
        } else {
            return sdk.size(for: node).uint64Value
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
        
        return NodeEntity(node: node)
    }

    func creationDateForNode(handle: MEGAHandle) -> Date? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.creationTime
    }
}
