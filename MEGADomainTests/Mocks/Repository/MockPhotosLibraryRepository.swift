@testable import MEGA

struct MockPhotosLibraryRepository: PhotoLibraryRepositoryProtocol {
    static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
    }
    
    var cloudDriveNode: MEGANode?
    var cameraUploadNode: MEGANode?
    var mediaUploadNode: MEGANode?
    
    var nodesInCloudDriveOnly: [MEGANode] = []
    var nodesInCameraUpload: [MEGANode] = []
    var nodesInMediaUpload: [MEGANode] = []
    
    var videoNodes: [MEGANode] = []
    
    func node(in source: PhotoSourceEntity) async throws -> MEGANode? {
        source == .camera ? cameraUploadNode : mediaUploadNode
    }
    
    func nodes(inParent parentNode: MEGANode?) -> [MEGANode] {
        if parentNode == cloudDriveNode {
            return nodesInCloudDriveOnly
        } else if parentNode == cameraUploadNode {
            return nodesInCameraUpload
        } else {
            return nodesInMediaUpload
        }
    }
    
    func videoNodes(inParent parentNode: MEGANode?) -> [MEGANode] {
        videoNodes
    }
}
