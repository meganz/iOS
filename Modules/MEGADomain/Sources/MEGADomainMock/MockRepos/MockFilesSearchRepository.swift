import Foundation
import MEGADomain

final public class MockFilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockFilesSearchRepository()
    
    public var hasCancelSearchCalled = false
    
    private let photoNodes: [NodeEntity]
    private let videoNodes: [NodeEntity]
    
    public var callback: (([NodeEntity]) -> Void)?
    
    public init(photoNodes: [NodeEntity] = [], videoNodes: [NodeEntity] = []) {
        self.photoNodes = photoNodes
        self.videoNodes = videoNodes
    }
    
    public func allPhotos() async throws -> [NodeEntity] {
        photoNodes
    }
    
    public func allVideos() async throws -> [NodeEntity] {
        videoNodes
    }
    
    public func startMonitoringNodesUpdate(callback: @escaping ([NodeEntity]) -> Void) {
        self.callback = callback
    }
    
    public func stopMonitoringNodesUpdate() {
        self.callback = nil
    }
    
    public func node(by id: HandleEntity) async -> NodeEntity? {
        (photoNodes + videoNodes).first { node in
            node.handle == id
        }
    }
    
    public func search(string: String?,
                       parent node:NodeEntity?,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity,
                       completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        
    }
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        if formatType == .photo {
            return photoNodes
        } else if formatType == .video {
            return videoNodes
        } else {
            return []
        }
    }
    
    public func cancelSearch() {
        hasCancelSearchCalled = true
    }
}
