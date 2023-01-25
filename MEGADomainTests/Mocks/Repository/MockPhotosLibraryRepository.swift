@testable import MEGA
import MEGADomain

struct MockPhotosLibraryRepository: PhotoLibraryRepositoryProtocol {
    static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
    }
    
    var cloudDriveNode: NodeEntity?
    var cameraUploadNode: NodeEntity?
    var mediaUploadNode: NodeEntity?
    
    var nodesInCloudDriveOnly: [NodeEntity] = []
    var nodesInCameraUpload: [NodeEntity] = []
    var nodesInMediaUpload: [NodeEntity] = []
    
    var videoNodes: [NodeEntity] = []
    
    func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity? {
        source == .camera ? cameraUploadNode : mediaUploadNode
    }
    
    func visualMediaNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        if parentNode == cloudDriveNode {
            return nodesInCloudDriveOnly
        } else if parentNode == cameraUploadNode {
            return nodesInCameraUpload
        } else {
            return nodesInMediaUpload
        }
    }
    
    func videoNodes(inParent parentNode: NodeEntity?) -> [NodeEntity] {
        videoNodes
    }
}
