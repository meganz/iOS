import MEGADomain
import MEGAUI
import UIKit

protocol NodeInsertionRouting {
    func createTextFileAlert(for nodeEntity: NodeEntity)
    func createNewFolder(for nodeEntity: NodeEntity)
    func scanDocument(for nodeEntity: NodeEntity)
    func importFromFiles(for nodeEntity: NodeEntity)
    func capturePhotoVideo(for nodeEntity: NodeEntity)
    func choosePhotoVideo(for nodeEntity: NodeEntity) async
}

struct CloudDriveNodeInsertionRouter: NodeInsertionRouting {
    private let navigationController: UINavigationController
    private let openNodeHandler: (NodeEntity) -> Void

    init(navigationController: UINavigationController, openNodeHandler: @escaping (NodeEntity) -> Void) {
        self.navigationController = navigationController
        self.openNodeHandler = openNodeHandler
    }

    func createTextFileAlert(for nodeEntity: NodeEntity) {
        CreateTextFileAlertViewRouter(presenter: navigationController, parentHandle: nodeEntity.handle).start()
    }

    func createNewFolder(for nodeEntity: NodeEntity) {
        Task { @MainActor in
            let router = CreateNewFolderAlertViewRouter(
                navigationController: navigationController,
                parentNode: nodeEntity
            )
            if let node = await router.start() {
                openNodeHandler(node)
            }
        }
    }

    func scanDocument(for nodeEntity: NodeEntity) {
        Task {
            let scanDocumentRouter = ScanDocumentViewRouter(presenter: navigationController, parent: nodeEntity)
            await scanDocumentRouter.start()
        }
    }

    func importFromFiles(for nodeEntity: NodeEntity) {
        DocumentPickerViewRouter(presenter: navigationController, parent: nodeEntity).start()
    }

    func capturePhotoVideo(for nodeEntity: NodeEntity) {
        CloudDriveMediaCaptureRouter(parentNode: nodeEntity, presenter: navigationController).start()
    }

    @MainActor
    func choosePhotoVideo(for nodeEntity: NodeEntity) {
        CloudDrivePhotosPickerRouter(
            parentNode: nodeEntity,
            presenter: navigationController,
            assetUploader: CloudDriveAssetUploader(),
            photoPicker: MEGAPhotoPicker(presenter: navigationController)
        ).start()
    }
}
