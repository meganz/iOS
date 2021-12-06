import Foundation

protocol HomeUploadingViewModelInputs {

    func viewIsReady()

    func didTapUploadFromSourceItems() -> [FileUploadingSourceItem]

    // MARK: - Event for user tapping uploading options

    func didTapUploadFromPhotoAlbum()
    
    func didTapUploadFromNewTextFile()

    func didTapUploadFromCamera()

    func didTapUploadFromImports()

    func didTapUploadFromDocumentScan()
}

protocol HomeUploadingViewModelOutputs {

    var state: HomeUploadingViewState { get }

    var networkReachable: Bool { get }
}

protocol HomeUploadingViewModelType {

    var inputs: HomeUploadingViewModelInputs { get }

    var outputs: HomeUploadingViewModelOutputs { get }

    var notifyUpdate: ((HomeUploadingViewModelOutputs) -> Void)? { get set }
}

final class HomeUploadingViewModel: HomeUploadingViewModelType, HomeUploadingViewModelInputs {

    // MARK: - HomeUploadingViewModelInputs

    func viewIsReady() {
        reachabilityUseCase.registerNetworkChangeListener { [weak self] _ in
            guard let self = self else { return }
            self.notifyUpdate?(self.outputs)
        }
    }

    func didTapUploadFromSourceItems() -> [FileUploadingSourceItem] {
        return uploadFilesUseCase.uploadOptions().map { source in
            switch source {
            case .photos: return FileUploadingSourceItem(source: .photos)
            case .textFile: return FileUploadingSourceItem(source: .textFile)
            case .camera: return FileUploadingSourceItem(source: .capture)
            case .imports: return FileUploadingSourceItem(source: .imports)
            case .documentScan: return FileUploadingSourceItem(source: .documentScan)
            }
        }
    }

    func didTapUploadFromPhotoAlbum() {
        devicePermissionUseCase.requestAlbumAccess { [weak self]  photoAlbumPermissionRequestResult in
            guard let self = self else { return }
            switch photoAlbumPermissionRequestResult {
            case .failure(let error):
                self.error = error
                self.notifyUpdate?(self.outputs)
            case .success:
                let selectionHandler: (([PHAsset], MEGANode) -> Void) = { [weak self] assets, targetNode in
                    guard let self = self else { return }
                    self.uploadFiles(fromPhotoAssets: assets, to: targetNode)
                }
                self.router.upload(from: .album(selectionHandler))
            }
        }
    }
    
    func didTapUploadFromNewTextFile() {
        router.upload(from: .textFile)
    }

    func didTapUploadFromCamera() {
        devicePermissionUseCase.requestVideoAccess { [weak self]  devicePermissionRequestResult in
            guard let self = self else { return }
            switch devicePermissionRequestResult {
            case .failure(let error): self.error = error
            case .success:
                let selectionHandler: (String, MEGANode) -> Void = { [weak self] filePath, targetNode in
                    guard let self = self else { return }
                    self.uploadFile(fromFilePath: filePath, to: targetNode)
                }
                self.router.upload(from: .camera(selectionHandler))
            }
            self.notifyUpdate?(self.outputs)
        }
    }

    func didTapUploadFromImports() {
        let selectionHandler: (URL, MEGANode) -> Void = { [weak self] url, targetNode in
            guard let self = self else { return }
            self.uploadFile(fromURL: url, to: targetNode)
        }
        router.upload(from: .imports(selectionHandler))
    }

    func didTapUploadFromDocumentScan() {
        devicePermissionUseCase.requestVideoAccess {  [weak self] devicePermissionRequestResult in
            guard let self = self else { return }
            switch devicePermissionRequestResult {
            case .failure(let error):
                self.error = error
                self.notifyUpdate?(self.outputs)
            case .success:
                self.router.upload(from: .documentScan)
            }
        }
    }

    private func uploadFiles(fromPhotoAssets assets: [PHAsset], to parentNode: MEGANode) {
        do {
            try uploadFilesUseCase.upload(
                photoIdentifiers: assets.map(\.localIdentifier),
                to: parentNode.handle
            )
        } catch {}
    }

    private func uploadFile(fromURL url: URL, to parentNode: MEGANode) {
        do {
            try uploadFilesUseCase.upload(from: url, to: parentNode.handle)
        } catch {}
    }

    func uploadFile(fromFilePath filePath: String, to node: MEGANode) {
        do {
            try uploadFilesUseCase.uploadFile(fromFilePath: filePath, to: node.handle)
        } catch {}
    }

    func uploadFile(fromSelectedImages images: [UIImage], to node: MEGANode) {
        do {
            try uploadFilesUseCase.uploadFile(fromSelectedImages: images, to: node.handle)
        } catch {}
    }

    private func notifyView(of error: DevicePermissionDeniedError) {
        self.error = error
        self.notifyUpdate?(self.outputs)
    }

    // MARK: - HomeUploadingViewModelOutputs

    private var error: DevicePermissionDeniedError?

    // MARK: - HomeUploadingViewModelType

    var inputs: HomeUploadingViewModelInputs { self }

    var outputs: HomeUploadingViewModelOutputs {
        let networkReachable = reachabilityUseCase.isReachable()
        if let error = error {
            return ViewState(
                state: .permissionDenied(error),
                networkReachable: networkReachable
            )
        }
        return ViewState(state: .normal, networkReachable: networkReachable)
    }

    var notifyUpdate: ((HomeUploadingViewModelOutputs) -> Void)?

    // MARK: - Router

    private let router: FileUploadingRouter

    // MARK: - Use Cases

    private let uploadFilesUseCase: HomeUploadFilesUseCaseProtocol

    private let devicePermissionUseCase: DevicePermissionRequestUseCaseProtocol

    private let reachabilityUseCase: ReachabilityUseCaseProtocol

    init(
        uploadFilesUseCase: HomeUploadFilesUseCaseProtocol,
        devicePermissionUseCase: DevicePermissionRequestUseCaseProtocol,
        reachabilityUseCase: ReachabilityUseCaseProtocol,
        router: FileUploadingRouter
    ) {
        self.uploadFilesUseCase = uploadFilesUseCase
        self.devicePermissionUseCase = devicePermissionUseCase
        self.reachabilityUseCase = reachabilityUseCase
        self.router = router
    }

    struct ViewState: HomeUploadingViewModelOutputs {
        var state: HomeUploadingViewState
        var networkReachable: Bool
    }
}

// MARK: - Upload Options

struct FileUploadingSourceItem {
    var title: String {
        switch source {
        case .photos: return HomeLocalisation.photos.rawValue
        case .textFile: return HomeLocalisation.textFile.rawValue
        case .capture: return HomeLocalisation.capture.rawValue
        case .imports: return HomeLocalisation.imports.rawValue
        case .documentScan: return HomeLocalisation.documentScan.rawValue
        }
    }
    var icon: UIImage {
        switch source {
        case .photos: return Asset.Images.NodeActions.saveToPhotos.image
        case .textFile: return Asset.Images.NodeActions.textfile.image
        case .capture: return Asset.Images.ActionSheetIcons.capture.image
        case .imports: return Asset.Images.InfoActions.import.image
        case .documentScan: return Asset.Images.ActionSheetIcons.scanDocument.image
        }
    }

    let source: Source

    enum Source {
        case photos
        case textFile
        case capture
        case imports
        case documentScan
    }
}

enum HomeUploadingViewState {
    case permissionDenied(DevicePermissionDeniedError)
    case normal
}
