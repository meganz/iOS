import Combine
import Foundation
import MEGADomain

final public class MockFilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    
    public static let newRepo = MockFilesSearchRepository()
    
    public var hasCancelSearchCalled = false
    
    private let photoNodes: [NodeEntity]
    private let videoNodes: [NodeEntity]
    
    public var callback: (([NodeEntity]) -> Void)?
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    public var startMonitoringNodesUpdateCalled = 0
    public var stopMonitoringNodesUpdateCalled = 0
    public var searchString: String?
    public var searchRecursive: Bool?
    
    public init(photoNodes: [NodeEntity] = [],
                videoNodes: [NodeEntity] = [],
                nodesUpdatePublisher: AnyPublisher<[NodeEntity], Never> = Empty().eraseToAnyPublisher()
    ) {
        self.photoNodes = photoNodes
        self.videoNodes = videoNodes
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
        (photoNodes + videoNodes).first { node in
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
        return switch filter.formatType {
        case .photo: photoNodes.filter { !$0.isFolder }
        case .video: videoNodes.filter { !$0.isFolder }
        default: []
        }
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
