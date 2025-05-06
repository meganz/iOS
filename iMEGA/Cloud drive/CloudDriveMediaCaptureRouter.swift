import MEGADomain
import MEGAPermissions
import MEGAPreference

struct CloudDriveMediaCaptureRouter {
    @PreferenceWrapper(key: PreferenceKeyEntity.isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var isSaveMediaCapturedToGalleryEnabled: Bool

    private let parentNode: NodeEntity
    private let presenter: UIViewController

    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }

    private var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }

    init(parentNode: NodeEntity, presenter: UIViewController) {
        self.parentNode = parentNode
        self.presenter = presenter
    }

    func start() {
        permissionHandler.requestVideoPermission { videoPermissionGranted in
            if videoPermissionGranted {
                permissionHandler.photosPermissionWithCompletionHandler { photosPermissionGranted in
                    if !photosPermissionGranted {
                        Self.isSaveMediaCapturedToGalleryEnabled = false
                    }
                    showImagePicker()
                }
            } else {
                permissionRouter.alertVideoPermission()
            }
        }
    }

    private func showImagePicker() {
        guard let imagePickerController = MEGAImagePickerController(
            toUploadWithParentNodeHandle: parentNode.handle,
            sourceType: .camera
        ) else {
            return
        }

        presenter.present(imagePickerController, animated: true)
    }
}
