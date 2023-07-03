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
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity,
                       completion: @escaping ([NodeEntity]?, Bool) -> Void) {
    }
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        if formatType == .photo {
            return photoNodes.filter { !$0.isFolder }
        } else if formatType == .video {
            return videoNodes.filter { !$0.isFolder }
        } else {
            return []
        }
    }
    
    public func cancelSearch() {
        hasCancelSearchCalled = true
    }
}
