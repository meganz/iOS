import Foundation
import MEGADomain

public struct MockNodeDataRepository: NodeDataRepositoryProtocol {
    public static let newRepo: MockNodeDataRepository = MockNodeDataRepository()
    
    private let nodeAccessLevel: NodeAccessTypeEntity
    private let labelString: String
    private let filesAndFoldersCount: (Int, Int)
    private let folderInfo: FolderInfoEntity?
    private let size: UInt64?
    private let modificationDate: Date
    private let node: NodeEntity?
    private let parentNode: NodeEntity?
    
    public init(
        nodeAccessLevel: NodeAccessTypeEntity = .unknown,
        labelString: String = "",
        filesAndFoldersCount: (Int, Int) = (0, 0),
        folderInfo: FolderInfoEntity? = nil,
        size: UInt64? = nil,
        modificationDate: Date = Date(),
        node: NodeEntity? = nil,
        parentNode: NodeEntity? = nil
    ) {
        self.nodeAccessLevel = nodeAccessLevel
        self.labelString = labelString
        self.filesAndFoldersCount = filesAndFoldersCount
        self.folderInfo = folderInfo
        self.size = size
        self.modificationDate = modificationDate
        self.node = node
        self.parentNode = parentNode
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
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        folderInfo
    }

    public func sizeForNode(handle: HandleEntity) -> UInt64? {
        size
    }
    
    public func creationDateForNode(handle: HandleEntity) -> Date? {
        modificationDate
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        node
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        parentNode
    }
}
