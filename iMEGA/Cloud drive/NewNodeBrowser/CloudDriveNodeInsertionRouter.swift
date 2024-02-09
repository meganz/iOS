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
        // scan document
    }

    func importFromFiles(for nodeEntity: NodeEntity) {
        // import files
    }

    func capturePhotoVideo(for nodeEntity: NodeEntity) {
        // capture photos
    }

    func choosePhotoVideo(for nodeEntity: NodeEntity) {
        // choose photo or video
    }
}
