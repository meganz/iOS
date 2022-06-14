
struct NodeRepository: NodeRepositoryProtocol {
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk

    init(sdk: MEGASdk, chatSdk: MEGAChatSdk = MEGASdkManager.sharedMEGAChatSdk()) {
        self.sdk = sdk
        self.chatSdk = chatSdk
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
    
    func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: MEGAHandle) -> Bool {
        guard let fileFingerprint = sdk.fingerprint(forFilePath: path),
              let parentNode = sdk.node(forHandle: parentHandle),
              let node = sdk.node(forFingerprint: fileFingerprint) else {
            return false
        }
        
        if node.parentHandle != parentHandle {
            sdk.copy(node, newParent: parentNode)
        }
        
        return true
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
}
