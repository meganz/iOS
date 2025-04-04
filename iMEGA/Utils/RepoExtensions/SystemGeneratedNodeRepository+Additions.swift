import Foundation
import MEGAAppSDKRepo
import MEGADomain

extension SystemGeneratedNodeRepository: @retroactive RepositoryProtocol {
    public static var newRepo: Self {
        SystemGeneratedNodeRepository(
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared,
            mediaUploadNodeAccess: MediaUploadNodeAccess.shared,
            myChatFilesFolderNodeAccess: MyChatFilesFolderNodeAccess.shared)
    }
}
