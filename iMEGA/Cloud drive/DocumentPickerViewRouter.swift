import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASwift

extension UIViewController {
    private static var megaDocumentPickerDelegateKey: UInt8 = 0
    fileprivate var megaDocumentPickerDelegate: DocumentPickerDelegate? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.megaDocumentPickerDelegateKey) as? DocumentPickerDelegate
        }
        set {
            objc_setAssociatedObject(self, &UIViewController.megaDocumentPickerDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

final class DocumentPickerViewRouter {
    private let presenter: UIViewController
    private let parent: NodeEntity

    init(presenter: UIViewController, parent: NodeEntity) {
        self.presenter = presenter
        self.parent = parent
    }

    func start() {
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.data, UTType.package],
            asCopy: true
        )

        let metadataUseCase = MetadataUseCase(
            metadataRepository: MetadataRepository(),
            fileSystemRepository: FileSystemRepository.sharedRepo,
            fileExtensionRepository: FileExtensionRepository(),
            nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
        )

        let delegate = DocumentPickerDelegate(
            parent: parent,
            presenter: presenter,
            router: self,
            metadataUseCase: metadataUseCase
        )
        documentPicker.delegate = delegate
        documentPicker.megaDocumentPickerDelegate = delegate

        documentPicker.allowsMultipleSelection = true
        presenter.present(documentPicker, animated: true)
    }
}

private final class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let parent: NodeEntity
    private var router: DocumentPickerViewRouter?
    private let presenter: UIViewController
    private let metadataUseCase: any MetadataUseCaseProtocol

    init(
        parent: NodeEntity,
        presenter: UIViewController,
        router: DocumentPickerViewRouter,
        metadataUseCase: some MetadataUseCaseProtocol
    ) {
        self.parent = parent
        self.presenter = presenter
        self.router = router
        self.metadataUseCase = metadataUseCase
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Task {
            let transfers = await buildTransfer(for: urls, parentHandle: parent.handle)

            CancellableTransferRouterOCWrapper().uploadFiles(
                transfers,
                presenter: presenter,
                type: .upload
            )
            
            self.router = nil
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.router = nil
    }
    
    private func buildTransfer(for urls: [URL], parentHandle: HandleEntity) async -> [CancellableTransfer] {
        await withTaskGroup(of: CancellableTransfer.self) { taskGroup in
            for url in urls {
                taskGroup.addTask {
                    var fileURL = url
                    if !url.path.contains("/tmp/") {
                        fileURL = URL(fileURLWithPath: NSHomeDirectory().append(pathComponent: url.path))
                    }
                    
                    let appData = await self.metadataUseCase.formattedCoordinate(forFileURL: fileURL)
                    
                    return CancellableTransfer(
                        handle: .invalid,
                        parentHandle: parentHandle,
                        fileLinkURL: nil,
                        localFileURL: fileURL,
                        name: nil,
                        appData: appData,
                        priority: false,
                        isFile: true,
                        type: .upload
                    )
                }
            }
            
            var transfers: [CancellableTransfer] = []
            for await transfer in taskGroup {
                transfers.append(transfer)
            }
            return transfers
        }
    }
}
