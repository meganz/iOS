import Foundation
import MEGADomain

public struct MockPhotosLibraryRepository: PhotoLibraryRepositoryProtocol {
    public static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
    }
    
    private var cloudDriveNode: NodeEntity?
    private var cameraUploadNode: NodeEntity?
    private var mediaUploadNode: NodeEntity?
    private var nodesInCloudDriveOnly: [NodeEntity]
    private var nodesInCameraUpload: [NodeEntity]
    private var nodesInMediaUpload: [NodeEntity]
    private var videoNodes: [NodeEntity]
    
    public init(cloudDriveNode: NodeEntity? = nil,
                cameraUploadNode: NodeEntity? = nil,
                mediaUploadNode: NodeEntity? = nil,
                nodesInCloudDriveOnly: [NodeEntity]  = [],
                nodesInCameraUpload: [NodeEntity] = [],
                nodesInMediaUpload: [NodeEntity]  = [],
                videoNodes: [NodeEntity] = []) {
        self.cloudDriveNode = cloudDriveNode
        self.cameraUploadNode = cameraUploadNode
        self.mediaUploadNode = mediaUploadNode
        self.nodesInCloudDriveOnly = nodesInCloudDriveOnly
        self.nodesInCameraUpload = nodesInCameraUpload
        self.nodesInMediaUpload = nodesInMediaUpload
        self.videoNodes = videoNodes
    }
    
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
