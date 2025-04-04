import MEGAAppSDKRepo
import MEGAL10n

extension CameraUploadNodeAccess {
    #if MNZ_SHARE_EXTENSION
    @objc static let shared = CameraUploadNodeAccess(autoCreate: false, nodeName: Strings.Localizable.General.cameraUploads)
    #else
    @objc static let shared = CameraUploadNodeAccess(autoCreate: CameraUploadManager.isCameraUploadEnabled, nodeName: Strings.Localizable.General.cameraUploads)
    #endif
}
