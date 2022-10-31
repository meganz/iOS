import MEGADomain
import Foundation

public struct MockNodeRepository: NodeRepositoryProtocol {
    public static let newRepo = MockNodeRepository()
    
    private let node: NodeEntity?
    private let rubbisNode: NodeEntity?
    private let nodeAccessLevel:NodeAccessTypeEntity
    private let isDownloaded: Bool
    private let hasVersions: Bool
    private let isInRubbishBin: Bool
    private let labelString: String
    private let childNodeNamed: NodeEntity?
    private let filesAndFoldersCount: (Int, Int)
    private let name: String?
    private let size: UInt64?
    private let base64Handle: String?
    private let isFile: Bool
    private let copiedNodeIfExists: Bool
    private let fingerprint: String?
    private let existsChildNode: Bool
    private let childNode: NodeEntity?
    private let modificationDate: Date
    private let copiedNodeHandle: UInt64?
    private let movedNodeHandle: UInt64?
    private let images: [NodeEntity]
    private let fileLinkNode: NodeEntity?
    private let isNodeDescendant: Bool
    
    public init(node: NodeEntity? = nil, rubbishNode: NodeEntity? = nil, nodeAccessLevel:NodeAccessTypeEntity = .unknown, isDownloaded: Bool = false, hasVersions: Bool = false, isInRubbishBin: Bool = false, labelString: String = "", childNodeNamed: NodeEntity? = nil, filesAndFoldersCount: (Int, Int) = (0, 0), name: String? = nil, size: UInt64? = nil, base64Handle: String? = nil, isFile: Bool = false, copiedNodeIfExists: Bool = false, fingerprint: String? = nil, existsChildNode: Bool = false, childNode: NodeEntity? = nil, modificationDate: Date = Date(), copiedNodeHandle: UInt64? = nil, movedNodeHandle: UInt64? = nil, images: [NodeEntity] = [], fileLinkNode: NodeEntity? = nil, isNodeDescendant: Bool = false) {
        self.node = node
        self.rubbisNode = rubbishNode
        self.nodeAccessLevel = nodeAccessLevel
        self.isDownloaded = isDownloaded
        self.hasVersions = hasVersions
        self.isInRubbishBin = isInRubbishBin
        self.labelString = labelString
        self.childNodeNamed = childNodeNamed
        self.filesAndFoldersCount = filesAndFoldersCount
        self.name = name
        self.size = size
        self.base64Handle = base64Handle
        self.isFile = isFile
        self.copiedNodeIfExists = copiedNodeIfExists
        self.fingerprint = fingerprint
        self.existsChildNode = existsChildNode
        self.childNode = childNode
        self.modificationDate = modificationDate
        self.copiedNodeHandle = copiedNodeHandle
        self.movedNodeHandle = movedNodeHandle
        self.images = images
        self.fileLinkNode = fileLinkNode
        self.isNodeDescendant = isNodeDescendant
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        node
    }

    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        nodeAccessLevel
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        labelString
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        filesAndFoldersCount
    }
    
    public func hasVersions(nodeHandle: HandleEntity) -> Bool {
        hasVersions
    }
    
    public func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        isDownloaded
    }
    
    public func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        isInRubbishBin
    }
    
    public func nameForNode(handle: HandleEntity) -> String? {
        name
    }
    
    public func nameForChatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> String? {
        name
    }
    
    public func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void) {
        guard let node = fileLinkNode else {
            completion(.failure(.nodeNotFound))
            return
        }
        completion(.success(node))
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        guard let node = fileLinkNode else {
            throw NodeErrorEntity.nodeNotFound
        }
        return node
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
    
    public func chatNode(handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity) -> NodeEntity? {
        node
    }

    public func isFileNode(handle: HandleEntity) -> Bool {
        isFile
    }
    
    public func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: HandleEntity, newName: String?) -> Bool {
        copiedNodeIfExists
    }
    
    public func copyNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?, isFolderLink: Bool) async throws -> HandleEntity {
        guard let copiedNodeHandle = copiedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return copiedNodeHandle
    }
    
    public func moveNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?) async throws -> HandleEntity {
        guard let movedNodeHandle = movedNodeHandle else {
            throw CopyOrMoveErrorEntity.generic
        }
        return movedNodeHandle
    }
    
    public func fingerprintForFile(at path: String) -> String? {
        fingerprint
    }
    
    public func setNodeCoordinates(nodeHandle: HandleEntity, latitude: Double, longitude: Double) {    }
    
    public func existChildNodeNamed(name: String, in parentHandle: HandleEntity) -> Bool {
        existsChildNode
    }
    
    public func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        childNode
    }
    
    public func creationDateForNode(handle: HandleEntity) -> Date? {
        modificationDate
    }
    
    public func images(for parentNode: NodeEntity) -> [NodeEntity] {
        images
    }
    
    public func images(for parentHandle: HandleEntity) -> [NodeEntity] {
        images
    }
    
    public func rubbishNode() -> NodeEntity? {
        rubbisNode
    }
    
    public func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool {
        isNodeDescendant
    }
}
