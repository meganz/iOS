import CoreServices
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGAUI
import VisionKit

final class FileUploadingRouter {
    private var browserVCDelegate: TargetFolderBrowserVCDelegate?
    
    private lazy var vNDocumentCameraVCDelegate: VNDocumentCameraVCDelegate? = nil
    
    private weak var navigationController: UINavigationController?

    private weak var baseViewController: UIViewController?
    
    private var photoPicker: any MEGAPhotoPickerProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    // MARK: - Initialiser

    init(
        navigationController: UINavigationController? = nil,
        baseViewController: UIViewController,
        photoPicker: some MEGAPhotoPickerProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.baseViewController = baseViewController
        self.photoPicker = photoPicker
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    func upload(from source: FileUploadSource) {
        switch source {
        case .album(let completion):
            presentPhotoAlbumSelection(completion: completion)
        case .textFile:
            CreateTextFileAlertViewRouter(presenter: navigationController).start()
        case .camera:
            presentCameraViewController()
        case .imports:
            presentImportSelection()
        case .documentScan:
            presentDocumentScanViewController()
        }
    }

    // MARK: - Display PhotoAlbum Selection View Controller

    private func presentPhotoAlbumSelection(completion: @escaping (([PHAsset], MEGANode) -> Void)) {
        Task { @MainActor in
            let assets = await photoPicker.pickAssets()
            if assets.count > 0 {
                self.presentDestinationFolderBrowser { targetNode in
                    completion(assets, targetNode)
                }
            }
        }
    }

    // MARK: - Display Import Selection View Controller

    private func presentImportSelection() {
        let documentPickerViewController = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.package], asCopy: true)
        documentPickerViewController.allowsMultipleSelection = true

        var documentImportsDelegate: DocumentImportsDelegate? {
            let documentImportsDelegate = DocumentImportsDelegate()
            documentImportsDelegate.navigationController = navigationController
            documentImportsDelegate.importsURLsCompletion = { [documentImportsDelegate, weak self] urls in
                _ = documentImportsDelegate
                asyncOnMain {
                    self?.presentDestinationFolderBrowser { [weak self] parentNode in
                        guard let presenter = self?.navigationController else {
                            return
                        }
                        self?.uploadImportedDocuments(at: urls, to: parentNode, presenter: presenter)
                    }
                }
            }
            return documentImportsDelegate
        }

        if let popover = documentPickerViewController.popoverPresentationController {
            guard let barItem = baseViewController?.navigationItem.rightBarButtonItems?.first else {
                return
            }
            
            popover.barButtonItem = barItem
        }
        
        documentPickerViewController.delegate = documentImportsDelegate
        navigationController?.present(documentPickerViewController, animated: true, completion: nil)
    }
    
    private func uploadImportedDocuments(at urls: [URL], to parentNode: MEGANode, presenter: UIViewController) {
        Task { @MainActor in
            let transfers = await self.buildTransfers(for: urls, parentHandle: parentNode.handle)
            let collisionEntities = transfers.map { NameCollisionEntity(parentHandle: $0.parentHandle, name: $0.localFileURL?.lastPathComponent ?? "", isFile: $0.isFile, fileUrl: $0.localFileURL) }
            NameCollisionViewRouter(presenter: presenter, transfers: transfers, nodes: nil, collisions: collisionEntities, collisionType: .upload).start()
        }
    }
    
    private func buildTransfers(for urls: [URL], parentHandle: HandleEntity) async -> [CancellableTransfer] {
        let metadataUseCase = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )
        return await withTaskGroup(of: CancellableTransfer.self) { taskGroup in
            taskGroup.addTasksUnlessCancelled(for: urls) { url in
                let appData = await metadataUseCase.formattedCoordinate(forFileURL: url)
                
                return CancellableTransfer(
                    handle: .invalid,
                    parentHandle: parentHandle,
                    fileLinkURL: nil,
                    localFileURL: url,
                    name: nil,
                    appData: appData,
                    priority: false,
                    isFile: true,
                    type: .upload
                )
            }
            
            return await taskGroup.reduce(into: []) { $0.append($1) }
        }
    }

    // MARK: - Display Camera Capture View Controller

    private func presentCameraViewController() {
        asyncOnMain { [weak self] in
            guard let self else { return }
            let imagePickerController = UploadImagePickerViewController()
            try? imagePickerController.prepare(withSourceType: .camera) { [weak self] result in
                asyncOnMain {
                    guard let self else { return }
                    imagePickerController.dismiss(animated: true) {
                        switch result {
                        case .failure: break
                        case .success(let filePath):
                            self.presentDestinationFolderBrowser { [weak self] parentNode in
                                guard let presenter = self?.navigationController else {
                                    return
                                }
                                self?.uploadCapturedMedia(filePath: filePath, to: parentNode, presenter: presenter)
                            }
                        }
                    }
                }
            }
            self.navigationController?.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    private func uploadCapturedMedia(filePath: String, to parentNode: MEGANode, presenter: UIViewController) {
        Task { @MainActor in
            let url = URL(fileURLWithPath: filePath)
            let transfers = await buildTransfers(for: [url], parentHandle: parentNode.handle)
            CancellableTransferRouter.init(presenter: presenter, transfers: transfers, transferType: .upload).start()
        }
    }

    // MARK: - Display Document Scan View Controller
    private func presentDocumentScanViewController() {
        asyncOnMain { [weak self] in
            guard let self else { return }
            let scanViewController = VNDocumentCameraViewController()
            let vNDocumentCameraVCDelegate = VNDocumentCameraVCDelegate()
            vNDocumentCameraVCDelegate.completion = { [weak self] images in
                asyncOnMain {
                    guard let self else { return }
                    scanViewController.dismiss(animated: true, completion: nil)
                    let rootNode = MEGASdk.shared.rootNode
                    let documentScanViewController = self.documentScanerSaveSettingViewController(parentNode: rootNode, images: images)
                    self.navigationController?.present(documentScanViewController, animated: true, completion: nil)
                }
            }
            scanViewController.delegate = vNDocumentCameraVCDelegate
            self.vNDocumentCameraVCDelegate = vNDocumentCameraVCDelegate
            self.navigationController?.present(scanViewController, animated: true, completion: nil)
        }
    }

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
        browserVCDelegate = TargetFolderBrowserVCDelegate()
        browserVCDelegate?.completion = { node in
            browserViewController.dismiss(animated: true) {
                completion(node)
            }
        }

        browserViewController.browserViewControllerDelegate = browserVCDelegate
        browserViewController.browserAction = .newHomeUpload
        let browserNavigationController = MEGANavigationController(rootViewController: browserViewController)
        browserNavigationController.setToolbarHidden(false, animated: false)
        navigationController?.present(browserNavigationController, animated: true, completion: nil)
    }

    // MARK: - Event Source

    enum FileUploadSource {
        // Upload from photo album
        case album(_ completion: ([PHAsset], MEGANode) -> Void)
        
        // Upload from new text file
        case textFile

        // Upload from camera
        case camera

        // Upload from imports
        case imports

        // Upload from document scan
        case documentScan
    }
}

private final class DocumentImportsDelegate: NSObject, UIDocumentPickerDelegate {

    weak var navigationController: UINavigationController?

    var importsURLsCompletion: (([URL]) -> Void)?

    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        importsURLsCompletion?(urls)
        importsURLsCompletion = nil
    }
}

final class TargetFolderBrowserVCDelegate: NSObject, BrowserViewControllerDelegate {
    var completion: ((MEGANode) -> Void)?

    func upload(toParentNode parentNode: MEGANode) {
        asyncOnMain(weakify(self) {
            $0.completion?(parentNode)
        })
    }
}

private final class VNDocumentCameraVCDelegate: NSObject, VNDocumentCameraViewControllerDelegate {
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
        })
    }
}
