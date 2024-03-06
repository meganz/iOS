import MEGADomain
import MEGARepo
import MEGASwift

final class DocumentPickerViewRouter {
    private let presenter: UIViewController
    private let parent: NodeEntity
    private var pickerDelegate: DocumentPickerDelegate?

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
            fileSystemRepository: FileSystemRepository(fileManager: .default),
            fileExtensionRepository: FileExtensionRepository()
        )

        let delegate = DocumentPickerDelegate(
            parent: parent,
            presenter: presenter,
            router: self,
            metadataUseCase: metadataUseCase
        )
        documentPicker.delegate = delegate
        pickerDelegate = delegate

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
        let transfers = urls.compactMap { url in
            var fileURL = url
            if !url.path.contains("/tmp/") {
                fileURL = URL(fileURLWithPath: NSHomeDirectory().append(pathComponent: url.path))
            }

            var appData: String?
            if let coordinate = metadataUseCase.coordinateInTheFile(at: fileURL) {
                appData = metadataUseCase.formatCoordinate(coordinate)
            }

            return CancellableTransfer(
                handle: .invalid,
                parentHandle: parent.handle,
                fileLinkURL: nil,
                localFileURL: fileURL,
                name: nil,
                appData: appData,
                priority: false,
                isFile: true,
                type: .upload
            )
        }

        CancellableTransferRouterOCWrapper().uploadFiles(
            transfers,
            presenter: presenter,
            type: .upload
        )

        self.router = nil
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.router = nil
    }
}

/// Need to move this to MEGARepo in the future when refactoring `fileExtensionGroup`
private final class FileExtensionRepository: FileExtensionRepositoryProtocol {
    func isImage(url: URL) -> Bool {
        url.fileExtensionGroup.isImage
    }
    
    func isVideo(url: URL) -> Bool {
        url.fileExtensionGroup.isVideo
    }
}
