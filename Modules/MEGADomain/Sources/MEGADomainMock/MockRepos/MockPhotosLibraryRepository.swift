import Foundation
import MEGADomain

public struct MockPhotosLibraryRepository: PhotoLibraryRepositoryProtocol {
    public static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
    }
    
    public var cloudDriveNode: NodeEntity?
    public var cameraUploadNode: NodeEntity?
    public var mediaUploadNode: NodeEntity?
    
    public var nodesInCloudDriveOnly: [NodeEntity] = []
    public var nodesInCameraUpload: [NodeEntity] = []
    public var nodesInMediaUpload: [NodeEntity] = []
    
    public var videoNodes: [NodeEntity] = []
    
    public func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity? {
        source == .camera ? cameraUploadNode : mediaUploadNode
    }
    
    public func visualMediaNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        if parentNode == cloudDriveNode {
            return nodesInCloudDriveOnly
        } else if parentNode == cameraUploadNode {
            return nodesInCameraUpload
        } else {
            return nodesInMediaUpload
        }
    }
    
    public func videoNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        videoNodes
    }
}
