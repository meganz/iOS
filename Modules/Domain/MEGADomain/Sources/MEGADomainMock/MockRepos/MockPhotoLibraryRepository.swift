import Foundation
import MEGADomain

public struct MockPhotoLibraryRepository: PhotoLibraryRepositoryProtocol {
    public static var newRepo: MockPhotoLibraryRepository {
        MockPhotoLibraryRepository()
    }
    
    private var cloudDriveNode: NodeEntity?
    private var cameraUploadNode: NodeEntity?
    private var mediaUploadNode: NodeEntity?
    
    public init(cloudDriveNode: NodeEntity? = nil,
                cameraUploadNode: NodeEntity? = nil,
                mediaUploadNode: NodeEntity? = nil) {
        self.cloudDriveNode = cloudDriveNode
        self.cameraUploadNode = cameraUploadNode
        self.mediaUploadNode = mediaUploadNode
    }
    
    public func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity? {
        source == .camera ? cameraUploadNode : mediaUploadNode
    }
}
