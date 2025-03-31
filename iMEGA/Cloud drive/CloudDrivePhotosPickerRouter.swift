import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGAUI

protocol AssetUploader {
    func upload(assets: [PHAsset], to handle: MEGAHandle)
}

struct CloudDrivePhotosPickerRouter {
    private let parentNode: NodeEntity
    private let presenter: UIViewController
    private let assetUploader: any AssetUploader
    
    private var photoPicker: any MEGAPhotoPickerProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol

    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }

    private var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }

    init(
        parentNode: NodeEntity,
        presenter: UIViewController,
        assetUploader: some AssetUploader,
        photoPicker: some MEGAPhotoPickerProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol
    ) {
        self.parentNode = parentNode
        self.presenter = presenter
        self.assetUploader = assetUploader
        self.photoPicker = photoPicker
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }

    @MainActor
    func start() {
        permissionHandler.photosPermissionWithCompletionHandler { granted in
            if granted {
                Task { @MainActor in
                    let assets = await photoPicker.pickAssets()
                    assetUploader.upload(assets: assets, to: parentNode.handle)
                }
            } else {
                permissionRouter.alertPhotosPermission()
            }
        }
    }
}
