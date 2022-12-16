import Foundation
import MEGADomain

final public class MockFileSearchRepository: NSObject, FileSearchRepositoryProtocol {
    public static let newRepo = MockFileSearchRepository()
    
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
}
