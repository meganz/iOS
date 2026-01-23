import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAUI
import Photos

protocol AssetUploader {
    func upload(assets: [PHAsset], to handle: MEGAHandle)
}

@MainActor
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

    func start() {
        permissionHandler.photosPermissionWithCompletionHandler { [weak presenter] granted in
            guard let presenter else { return }

            if granted {
                Task { @MainActor [weak presenter] in
                    guard let presenter else { return }
                    let result = await photoPicker.pickAssets()
                    let assets = result.assets
                    let selectedCount = result.selectedCount
                    
                    if assets.count < selectedCount, PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                        let alert = UIAlertController(
                            title: Strings.Localizable.Photo.Picker.Alert.LimitAccess.title,
                            message: Strings.Localizable.Photo.Picker.Alert.LimitAccess.message,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: Strings.Localizable.Photo.Picker.Alert.LimitAccess.selectMore, style: .default) { [weak presenter] _ in
                            guard let presenter else { return }
                            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter)
                        })
                        alert.addAction(UIAlertAction(title: Strings.Localizable.Photo.Picker.Alert.LimitAccess.availableOnly, style: .default) { _ in
                            assetUploader.upload(assets: assets, to: parentNode.handle)
                        })
                        presenter.present(alert, animated: true)
                    } else {
                        assetUploader.upload(assets: assets, to: parentNode.handle)
                    }
                }
            } else {
                permissionRouter.alertPhotosPermission()
            }
        }
    }
}
