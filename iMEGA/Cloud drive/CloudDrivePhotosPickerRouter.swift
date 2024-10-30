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
        photoPicker: some MEGAPhotoPickerProtocol
    ) {
        self.parentNode = parentNode
        self.presenter = presenter
        self.assetUploader = assetUploader
        self.photoPicker = photoPicker
    }

    func start() {
        permissionHandler.photosPermissionWithCompletionHandler { granted in
            if granted {
                if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newPhotoPicker) {
                    Task { @MainActor in
                        let assets = await photoPicker.pickAssets()
                        assetUploader.upload(assets: assets, to: parentNode.handle)
                    }
                } else {
                    loadPhotoAlbumBrowser()
                }
            } else {
                permissionRouter.alertPhotosPermission()
            }
        }
    }
    
    // MARK: - Private
    
    private func loadPhotoAlbumBrowser() {
        let albumTableViewController = AlbumsTableViewController(
            selectionActionType: .upload,
            selectionActionDisabledText: Strings.Localizable.upload
        ) { assetUploader.upload(assets: $0, to: parentNode.handle) }
        
        let navigationController = MEGANavigationController(rootViewController: albumTableViewController)
        presenter.present(navigationController, animated: true)
    }
}
