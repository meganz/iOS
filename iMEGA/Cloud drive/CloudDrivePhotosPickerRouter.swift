import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAUI
import Photos
import PhotosUI

@MainActor
protocol AssetUploader {
    func importFromPhotos(results: [PHPickerResult], to parentNode: NodeEntity) async
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
        photoPicker.pickResults { [assetUploader, parentNode] results in
            guard !results.isEmpty else { return }
            Task {
                await assetUploader.importFromPhotos(results: results, to: parentNode)
            }
        }
    }
}
