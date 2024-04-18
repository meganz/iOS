import Foundation
import MEGADomain

public struct MockPhotosLibraryRepository: PhotoLibraryRepositoryProtocol {
    public static var newRepo: MockPhotosLibraryRepository {
        MockPhotosLibraryRepository()
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
