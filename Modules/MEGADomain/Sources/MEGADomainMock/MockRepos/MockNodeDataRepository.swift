import MEGADomain
import Foundation

public struct MockNodeDataRepository: NodeDataRepositoryProtocol {
    public static var newRepo: MockNodeDataRepository = MockNodeDataRepository()
    
    private let nodeAccessLevel:NodeAccessTypeEntity
    private let labelString: String
    private let filesAndFoldersCount: (Int, Int)
    private let name: String?
    private let size: UInt64?
    private let base64Handle: String?
    private let fingerprint: String?
    private let modificationDate: Date
    
    public init(nodeAccessLevel: NodeAccessTypeEntity = .unknown, labelString: String = "", filesAndFoldersCount: (Int, Int) = (0, 0), name: String? = nil, size: UInt64? = nil, base64Handle: String? = nil, fingerprint: String? = nil, modificationDate: Date = Date()) {
        self.nodeAccessLevel = nodeAccessLevel
        self.labelString = labelString
        self.filesAndFoldersCount = filesAndFoldersCount
        self.name = name
        self.size = size
        self.base64Handle = base64Handle
        self.fingerprint = fingerprint
        self.modificationDate = modificationDate
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFoldersCount
    }
    
    public func nameForNode(handle: HandleEntity) -> String? {
        name
    }
    
    public func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        name
    }
    
    public func sizeForNode(handle: HandleEntity) -> UInt64? {
        size
    }
    
    public func sizeForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> UInt64? {
        size
    }
    
    public func base64ForNode(handle: HandleEntity) -> String? {
        base64Handle
    }
    
    public func base64ForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        base64Handle
    }
    
    public func fingerprintForFile(at path: String) -> String? {
        fingerprint
    }
    
    public func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double) { }
    
    public func creationDateForNode(handle: HandleEntity) -> Date? {
        modificationDate
    }
}
