import Foundation
import MEGADomain

public struct MockNodeDataRepository: NodeDataRepositoryProtocol {
    public static var newRepo: MockNodeDataRepository = MockNodeDataRepository()
    
    private let nodeAccessLevel: NodeAccessTypeEntity
    private let labelString: String
    private let filesAndFoldersCount: (Int, Int)
    private let size: UInt64?
    private let modificationDate: Date
    
    public init(nodeAccessLevel: NodeAccessTypeEntity = .unknown, labelString: String = "", filesAndFoldersCount: (Int, Int) = (0, 0), size: UInt64? = nil, modificationDate: Date = Date()) {
        self.nodeAccessLevel = nodeAccessLevel
        self.labelString = labelString
        self.filesAndFoldersCount = filesAndFoldersCount
        self.size = size
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
    
    public func sizeForNode(handle: HandleEntity) -> UInt64? {
        size
    }
    
    public func creationDateForNode(handle: HandleEntity) -> Date? {
        modificationDate
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        nil
    }
}
