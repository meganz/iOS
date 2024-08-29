import Combine
import Foundation
import MEGADomain
import MEGASwift

final public class MockFilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
        
    public static let newRepo = MockFilesSearchRepository()
    
    public var hasCancelSearchCalled = false
    
    private let photoNodes: [NodeEntity]
    private let videoNodes: [NodeEntity]
    
    private let nodesForHandle: [HandleEntity: [NodeEntity]]
    private let nodeListEntityForHandle: [HandleEntity: NodeListEntity]
    private let nodesForLocation: [FolderTargetEntity: [NodeEntity]]
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    @Atomic public var callback: (([NodeEntity]) -> Void)?
    @Atomic public var startMonitoringNodesUpdateCalled = 0
    @Atomic public var stopMonitoringNodesUpdateCalled = 0
    @Atomic public var searchString: String?
    @Atomic public var searchRecursive: Bool?
    @Atomic public var messages = [Message]()
    
    public enum Message: Equatable, Sendable {
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
        self.$callback.mutate { $0 = callback }
        $startMonitoringNodesUpdateCalled.mutate { $0 += 1 }
    }
    
    public func stopMonitoringNodesUpdate() {
        self.$callback.mutate { $0 = nil }
        $stopMonitoringNodesUpdateCalled.mutate { $0 += 1 }
    }

    public func node(by id: HandleEntity) async -> NodeEntity? {
        $messages.mutate { $0.append(.node(id: id)) }
        return nodesForHandle
            .flatMap { $0.value }
            .first { node in node.handle == id }
    }
    
    public func search(filter: SearchFilterEntity, page: SearchPageEntity) async throws -> [NodeEntity] {
        let results: [NodeEntity] = try await search(filter: filter)
        guard page.startingOffset >= 0, page.pageSize > 0 else {
            return results
        }
        // simulate sdk ability to page results
        let start = page.startingOffset * page.pageSize
        let end = start + page.pageSize
        return Array(results[start..<end])
    }
    
    public func search(filter: SearchFilterEntity) async throws -> [NodeEntity] {
        $searchString.mutate { $0 = filter.searchText }
        $searchRecursive.mutate { $0 = filter.recursive }
        let message = Message.search(searchText: searchString,
                                     sortOrder: filter.sortOrderType)
        $messages.mutate { $0.append(message) }
        
        let filterCondition = { (node: NodeEntity) -> Bool in
            let sensitiveCondition = switch filter.sensitiveFilterOption {
            case .disabled: true
            case .nonSensitiveOnly: !node.isMarkedSensitive
            case .sensitiveOnly: node.isMarkedSensitive
            }
            
            let typeCondition = switch filter.formatType {
            case .photo: node.isFile && node.name.fileExtensionGroup.isImage
            case .video: node.isFile && node.name.fileExtensionGroup.isVideo
            case .unknown: true
            default: false
            }
            
            return [sensitiveCondition, typeCondition].allSatisfy { $0 }
        }
        
        let nodes = switch filter.searchTargetLocation {
        case .parentNode(let nodeEntity):
            nodesForHandle[nodeEntity.handle] ?? []
        case .folderTarget(let folderTargetEntity):
            nodesForLocation[folderTargetEntity] ?? []
        }
        
        return nodes
            .filter(filterCondition)
            .filter {
                switch filter.formatType {
                case .photo: $0.name.fileExtensionGroup.isImage
                case .video: $0.name.fileExtensionGroup.isVideo
                default: true
                }
            }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> NodeListEntity {
        $searchString.mutate { $0 = filter.searchText }
        $searchRecursive.mutate { $0 = filter.recursive }
        switch filter.searchTargetLocation {
        case .parentNode(let nodeEntity):
            if let nodeListEntity = nodeListEntityForHandle[nodeEntity.handle] {
                return nodeListEntity
            }
        case .folderTarget:
            break
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
        
        $searchString.mutate { $0 = string }
        $searchRecursive.mutate { $0 = recursive }
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
        $searchString.mutate { $0 = string }
        $searchRecursive.mutate { $0 = recursive }
        return switch formatType {
        case .photo: photoNodes.filter { !$0.isFolder }
        case .video: videoNodes.filter { !$0.isFolder }
        default: []
        }
    }
}
