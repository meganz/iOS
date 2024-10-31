import MEGAL10n
import MEGASDKRepo

extension CameraUploadNodeAccess {
    @objc static let shared = CameraUploadNodeAccess(autoCreate: CameraUploadManager.isCameraUploadEnabled, nodeName: Strings.Localizable.General.cameraUploads)
}
