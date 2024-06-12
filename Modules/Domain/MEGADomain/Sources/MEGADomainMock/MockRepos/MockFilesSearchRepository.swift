import Combine
import Foundation
import MEGADomain

final public class MockFilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    
    public static let newRepo = MockFilesSearchRepository()
    
    public var hasCancelSearchCalled = false
    
    private let photoNodes: [NodeEntity]
    private let videoNodes: [NodeEntity]
    private let nodesForHandle: [HandleEntity: [NodeEntity]]
    private let nodeListEntityForHandle: [HandleEntity: NodeListEntity]
    private let nodesForLocation: [FolderTargetEntity: [NodeEntity]]
    
    public var callback: (([NodeEntity]) -> Void)?
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    public var startMonitoringNodesUpdateCalled = 0
    public var stopMonitoringNodesUpdateCalled = 0
    public var searchString: String?
    public var searchRecursive: Bool?
    
    public private(set) var messages = [Message]()
    
    public enum Message: Equatable {
        case node(id: HandleEntity)
        case search(searchText: String?, sortOrder: SortOrderEntity)
    }
    
    public init(photoNodes: [NodeEntity] = [],
                videoNodes: [NodeEntity] = [],
                nodesForHandle: [HandleEntity: [NodeEntity]] = [:],
                nodeListEntityForHandle: [HandleEntity: NodeListEntity] = [:],
                nodesForLocation: [FolderTargetEntity: [NodeEntity]] = [:],
                nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never> = Empty().eraseToAnyPublisher()
    ) {
        self.photoNodes = photoNodes
        self.videoNodes = videoNodes
        self.nodesForHandle = nodesForHandle
        self.nodeListEntityForHandle = nodeListEntityForHandle
        self.nodesForLocation = nodesForLocation
        self.nodeUpdatesPublisher = nodesUpdatePublisher
    }
    
    public func startMonitoringNodesUpdate(callback: (([NodeEntity]) -> Void)?) {
        self.callback = callback
        startMonitoringNodesUpdateCalled += 1
    }
    
    public func stopMonitoringNodesUpdate() {
        self.callback = nil
        stopMonitoringNodesUpdateCalled += 1
    }

    public func node(by id: HandleEntity) async -> NodeEntity? {
        messages.append(.node(id: id))
        return (photoNodes + videoNodes).first { node in
            node.handle == id
        }
    }
    
    public func search(filter: SearchFilterEntity, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        searchString = filter.searchText
        searchRecursive = filter.recursive
        let nodes: [NodeEntity] = switch filter.formatType {
        case .photo: photoNodes.filter { !$0.isFolder }
        case .video: videoNodes.filter { !$0.isFolder }
        default: []
        }
        
        completion(nodes, false)
    }
    
    public func search(filter: SearchFilterEntity) async throws -> [NodeEntity] {
        searchString = filter.searchText
        searchRecursive = filter.recursive
        
        messages.append(.search(searchText: searchString, sortOrder: filter.sortOrderType))
        
        let filterCondition = { (node: NodeEntity) -> Bool in
            node.isFile && (filter.excludeSensitive ? !node.isMarkedSensitive : true)
        }
        
        if let parentHandle = filter.parentNode?.handle,
           let nodes = nodesForHandle[parentHandle] {
            return nodes
                .filter(filterCondition)
                .filter {
                    switch filter.formatType {
                    case .photo: $0.name.fileExtensionGroup.isImage
                    case .video: $0.name.fileExtensionGroup.isVideo
                    default: false
                    }
                }
        }
        
        if let folderTargetEntity = filter.folderTargetEntity, let nodes = nodesForLocation[folderTargetEntity] {
            return nodes
        }
        
        return switch filter.formatType {
        case .photo: photoNodes.filter(filterCondition)
        case .video: videoNodes.filter(filterCondition)
        default: []
        }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> NodeListEntity {
        searchString = filter.searchText
        searchRecursive = filter.recursive
        if let parentNodeHandle = filter.parentNode?.handle, let nodeListEntity = nodeListEntityForHandle[parentNodeHandle] {
            return nodeListEntity
        }
        throw NodeSearchResultErrorEntity.noDataAvailable
    }
        
    public func cancelSearch() {
        hasCancelSearchCalled = true
    }
}

// MARK: - Deprecated searchApi usage
extension MockFilesSearchRepository {
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       recursive: Bool,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity,
                       completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        
        searchString = string
        searchRecursive = recursive
        let nodes: [NodeEntity] = switch formatType {
        case .photo: photoNodes.filter { !$0.isFolder }
        case .video: videoNodes.filter { !$0.isFolder }
        default: []
        }
        
        completion(nodes, false)
    }
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       recursive: Bool,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        searchString = string
        searchRecursive = recursive
        return switch formatType {
        case .photo: photoNodes.filter { !$0.isFolder }
        case .video: videoNodes.filter { !$0.isFolder }
        default: []
        }
    }
}
