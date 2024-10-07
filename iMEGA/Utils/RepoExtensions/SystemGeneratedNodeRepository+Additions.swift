import Foundation
import MEGADomain
import MEGASDKRepo

extension SystemGeneratedNodeRepository: @retroactive RepositoryProtocol {
    public static var newRepo: Self {
        SystemGeneratedNodeRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared,
            mediaUploadNodeAccess: MediaUploadNodeAccess.shared,
            myChatFilesFolderNodeAccess: MyChatFilesFolderNodeAccess.shared)
    }
}
