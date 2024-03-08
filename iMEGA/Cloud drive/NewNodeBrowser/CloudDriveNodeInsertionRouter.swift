import MEGADomain
import UIKit

protocol NodeInsertionRouting {
    func createTextFileAlert(for nodeEntity: NodeEntity)
    func createNewFolder(for nodeEntity: NodeEntity)
    func scanDocument(for nodeEntity: NodeEntity)
    func importFromFiles(for nodeEntity: NodeEntity)
    func capturePhotoVideo(for nodeEntity: NodeEntity)
    func choosePhotoVideo(for nodeEntity: NodeEntity)
}

struct CloudDriveNodeInsertionRouter: NodeInsertionRouting {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func createTextFileAlert(for nodeEntity: NodeEntity) {
        // Create a text file
    }

    func createNewFolder(for nodeEntity: NodeEntity) {
        // create a folder
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

    func choosePhotoVideo(for nodeEntity: NodeEntity) {
        // choose photo or video
    }
}
