import Foundation
import CoreServices
import VisionKit

final class FileUploadingRouter {

    func didTrigger(from source: FileUploading) {
        switch source {
        case .album(let completion):
            presentPhotoAlbumSelection(completion: completion)
        case .camera(let completion):
            presentCameraViewController(withCompletion: completion)
        case .imports(let completion):
            presentImportSelection(withCompletion: completion)
        case .documentScan:
            if #available(iOS 13, *) {
                presentDocumentScanViewController()
            }
        }
    }

    // MARK: - Display PhotoAlbum Selection View Controller

    private func presentPhotoAlbumSelection(completion: @escaping (([PHAsset], MEGANode) -> Void)) {
        let albumTableViewController = AlbumsTableViewController(
            selectionActionText: HomeLocalisation.uploadWithNumber.rawValue,
            selectionActionDisabledText: HomeLocalisation.upload.rawValue
        ) { [weak self] assets in
            asyncOnMain {
                self?.presentDestinationFolderBrowser { targetNode in
                    completion(assets, targetNode)
                }
            }
        }
        asyncOnMain { [weak self] in
            guard let self = self else { return }
            self.navigationController?.present(
                MEGANavigationController(rootViewController: albumTableViewController),
                animated: true,
                completion: nil
            )
        }
    }

    // MARK: - Display Import Selection View Controller

    private func presentImportSelection(withCompletion completion: @escaping (URL, MEGANode) -> Void) {
        let documentMenuViewController = UIDocumentMenuViewController(
            documentTypes: [
                kUTTypeContent as String,
                kUTTypeData as String,
                kUTTypePackage as String,
                "com.apple.iwork.pages.pages",
                "com.apple.iwork.numbers.numbers",
                "com.apple.iwork.keynote.key"
            ],
            in: .import
        )

        var documentImportsDelegate: DocumentImportsDelegate? {
            let documentImportsDelegate = DocumentImportsDelegate()
            documentImportsDelegate.navigationController = navigationController
            documentImportsDelegate.importsURLCompletion = { [documentImportsDelegate, weak self] url in
                _ = documentImportsDelegate
                asyncOnMain {
                    self?.presentDestinationFolderBrowser(with: { targetNode in
                        completion(url, targetNode)
                    })
                }
            }
            return documentImportsDelegate
        }

        documentMenuViewController.delegate = documentImportsDelegate
        navigationController?.present(documentMenuViewController, animated: true, completion: nil)
    }

    // MARK: - Display Camera Capture View Controller

    private func presentCameraViewController(withCompletion completion: @escaping (String, MEGANode) -> Void) {
        asyncOnMain { [weak self] in
            guard let self = self else { return }
            let imagePickerController = UploadImagePickerViewController()
            try? imagePickerController.prepare(withSourceType: .camera) { [weak self] result in
                asyncOnMain {
                    guard let self = self else { return }
                    imagePickerController.dismiss(animated: true) {
                        switch result {
                        case .failure: break
                        case .success(let filePath):
                            self.presentDestinationFolderBrowser { parentNode in
                                completion(filePath, parentNode)
                            }
                        }
                    }
                }
            }
            self.navigationController?.present(imagePickerController, animated: true, completion: nil)
        }
    }

    // MARK: - Display Document Scan View Controller

    @available(iOS 13, *)
    private func presentDocumentScanViewController() {
        asyncOnMain { [weak self] in
            guard let self = self else { return }
            let scanViewController = VNDocumentCameraViewController()
            let scanViewControllerDelegate = DocumentScanViewControllerDelegate()
            scanViewControllerDelegate.completion = { [weak self, scanViewControllerDelegate] images in
                _ = scanViewControllerDelegate
                asyncOnMain {
                    guard let self = self else { return }
                    scanViewController.dismiss(animated: true, completion: nil)
                    let rootNode = MEGASdkManager.sharedMEGASdk().rootNode
                    let documentScanViewController = self.documentScanerSaveSettingViewController(parentNode: rootNode, images: images)
                    self.navigationController?.present(documentScanViewController, animated: true, completion: nil)
                }
            }
            scanViewController.delegate = scanViewControllerDelegate
            self.navigationController?.present(scanViewController, animated: true, completion: nil)
        }
    }

    @available(iOS 13, *)
    private func documentScanerSaveSettingViewController(parentNode: MEGANode?, images: [UIImage]) -> UIViewController {
        let docScanSettingViewController = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(identifier: "DocScannerSaveSettingTableViewController")
            as! DocScannerSaveSettingTableViewController
        docScanSettingViewController.parentNode = parentNode
        docScanSettingViewController.docs = images
        return MEGANavigationController(rootViewController: docScanSettingViewController)
    }

    // MARK: - Display Destination Folder Browser Controller

    private func presentDestinationFolderBrowser(with completion: @escaping (MEGANode) -> Void) {
        let browserViewController = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserViewControllerID") as! BrowserViewController
        let delegate = TargetFolderBrowserViewControllerDelegate()
        delegate.completion = { [delegate] node in
            _ = delegate
            completion(node)
            browserViewController.dismiss(animated: true, completion: nil)
        }

        browserViewController.browserViewControllerDelegate = delegate
        browserViewController.browserAction = .newHomeUpload
        let browserNavigationController = MEGANavigationController(rootViewController: browserViewController)
        browserNavigationController.setToolbarHidden(false, animated: false)
        navigationController?.present(browserNavigationController, animated: true, completion: nil)
    }

    // MARK: - Initialiser

    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }

    private weak var navigationController: UINavigationController?

    // MARK: - Event Source

    enum FileUploading {
        // Upload from photo album
        case album(_ completion: ([PHAsset], MEGANode) -> Void)

        // Upload from camera
        case camera(_ completion: (String, MEGANode) -> Void)

        // Upload from imports
        case imports(_ completion: (URL, MEGANode) -> Void)

        // Upload from document scan
        case documentScan
    }
}

fileprivate final class DocumentImportsDelegate: NSObject, UIDocumentMenuDelegate, UIDocumentPickerDelegate {

    weak var navigationController: UINavigationController?

    var importsURLCompletion: ((URL) -> Void)?

    // MARK: - UIDocumentMenuDelegate

    func documentMenu(
        _ documentMenu: UIDocumentMenuViewController,
        didPickDocumentPicker documentPicker: UIDocumentPickerViewController
    ) {
        documentPicker.delegate = self
        asyncOnMain(weakify(navigationController) { navigationController in
            navigationController.present(documentPicker, animated: true, completion: nil)
        })
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard controller.documentPickerMode == .import else { return }
        importsURLCompletion?(url)
        importsURLCompletion = nil
    }
}

fileprivate final class TargetFolderBrowserViewControllerDelegate: NSObject, BrowserViewControllerDelegate {
    var completion: ((MEGANode) -> Void)?

    func upload(toParentNode parentNode: MEGANode!) {
        asyncOnMain(weakify(self) {
            $0.completion?(parentNode)
            $0.completion = nil
        })
    }
}

@available(iOS 13, *)
fileprivate final class DocumentScanViewControllerDelegate: NSObject, VNDocumentCameraViewControllerDelegate {
    var completion: (([UIImage]) -> Void)?

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        let scanedImages = (0..<scan.pageCount).map { index in
            scan.imageOfPage(at: index)
        }
        asyncOnMain(weakify(self) {
            $0.completion?(scanedImages)
            $0.completion = nil
        })
    }
}
