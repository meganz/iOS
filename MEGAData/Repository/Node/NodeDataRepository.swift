import ChatRepo
import MEGADomain

struct NodeDataRepository: NodeDataRepositoryProtocol {
    static var newRepo: NodeDataRepository {
        NodeDataRepository(
            sdk: MEGASdk.shared, sharedFolderSdk: MEGASdk.sharedFolderLink, chatNodeRepository: ChatNodeRepository.newRepo)
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    private let chatNodeRepository: any ChatNodeRepositoryProtocol
    
    init(sdk: MEGASdk, sharedFolderSdk: MEGASdk, chatNodeRepository: any ChatNodeRepositoryProtocol) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.chatNodeRepository = chatNodeRepository
    }
    
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return .unknown
        }
        return NodeAccessTypeEntity(shareAccess: sdk.accessLevel(for: node)) ?? .unknown
    }
    
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        await Task.detached {
            nodeAccessLevel(nodeHandle: nodeHandle)
        }.value
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        let nodeLabel = MEGANodeLabel(nodeLabelTypeEntity: label) ?? .unknown
        return MEGANode.string(for: nodeLabel) ?? "" + "Small"
    }
    
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return (0, 0)
        }
        
        let numberOfFiles = sdk.numberChildFiles(forParent: node)
        let numberOfFolders = sdk.numberChildFolders(forParent: node)
        
        return (numberOfFiles, numberOfFolders)
    }
    
    func nameForNode(handle: HandleEntity) -> String? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.name
    }
    
    func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId)?.name
    }
    
    func sizeForNode(handle: HandleEntity) -> UInt64? {
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
    
    func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64? {
        chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId)?.size
    }
    
    func base64ForNode(handle: HandleEntity) -> String? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.base64Handle
    }
    
    func base64ForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        chatNodeRepository.chatNode(handle: handle, messageId: messageId, chatId: chatId)?.base64Handle
    }
    
    func fingerprintForFile(at path: String) -> String? {
        sdk.fingerprint(forFilePath: path)
    }
    
    func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return
        }
        if node.latitude != nil && node.longitude != nil {
            return
        }
        sdk.setNodeCoordinates(node, latitude: latitude as NSNumber, longitude: longitude as NSNumber)
    }
    
    func creationDateForNode(handle: HandleEntity) -> Date? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.creationTime
    }
    
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        guard let nodeEntity = nodeForHandle(handle),
              let node = nodeEntity.toMEGANode(in: sdk) else { return nil }
        return sdk.parentNode(for: node)?.toNodeEntity()
    }
}
