import Foundation

protocol HomeUploadingViewModelInputs {

    func viewIsReady()

    func didTapUploadFromSourceItems() -> [ContextActionSheetAction]?
}

protocol HomeUploadingViewModelOutputs {

    var state: HomeUploadingViewState { get }

    var networkReachable: Bool { get }
    
    @available(iOS 14.0, *)
    var contextMenu: UIMenu? { get }
}

protocol HomeUploadingViewModelType {

    var inputs: HomeUploadingViewModelInputs { get }

    var outputs: HomeUploadingViewModelOutputs { get }

    var notifyUpdate: ((HomeUploadingViewModelOutputs) -> Void)? { get set }
}

final class HomeUploadingViewModel: HomeUploadingViewModelType, HomeUploadingViewModelInputs {
    // MARK: - HomeUploadingViewModelInputs

    func viewIsReady() {
        self.contextMenuManager = ContextMenuManager(uploadAddMenuDelegate: self,
                                                     createContextMenuUseCase: createContextMenuUseCase)
        notifyUpdate?(self.outputs)
        
        reachabilityUseCase.registerNetworkChangeListener { [weak self] _ in
            guard let self = self else { return }
            self.notifyUpdate?(self.outputs)
        }
    }

    func didTapUploadFromSourceItems() -> [ContextActionSheetAction]? {
        let cmConfigEntity = CMConfigEntity(menuType: .uploadAdd, isHome: true)
        return contextMenuManager?.actionSheetActions(with: cmConfigEntity)
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
                self.router.upload(from: .camera)
            }
            self.notifyUpdate?(self.outputs)
        }
    }

    func didTapUploadFromImports() {
        router.upload(from: .imports)
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
        uploadPhotoAssetsUseCase.upload(photoIdentifiers: assets.map(\.localIdentifier), to: parentNode.handle)
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
        let cmConfigEntity = CMConfigEntity(menuType: .uploadAdd, isHome: true)
        if let error = error {
            if #available(iOS 14.0, *) {
                return ViewState(
                    state: .permissionDenied(error),
                    networkReachable: networkReachable,
                    contextMenu: contextMenuManager?.contextMenu(with: cmConfigEntity)
                )
            } else {
                return ViewState(
                    state: .permissionDenied(error),
                    networkReachable: networkReachable
                )
            }
        }
        
        if #available(iOS 14.0, *) {
            return ViewState(state: .normal,
                             networkReachable: networkReachable,
                             contextMenu: contextMenuManager?.contextMenu(with: cmConfigEntity)
            )
        } else {
            return ViewState(state: .normal,
                             networkReachable: networkReachable
            )
        }
    }

    var notifyUpdate: ((HomeUploadingViewModelOutputs) -> Void)?

    // MARK: - Router

    private let router: FileUploadingRouter

    // MARK: - Use Cases

    private let uploadPhotoAssetsUseCase: UploadPhotoAssetsUseCaseProtocol

    private let devicePermissionUseCase: DevicePermissionRequestUseCaseProtocol

    private let reachabilityUseCase: ReachabilityUseCaseProtocol
    
    private let createContextMenuUseCase: CreateContextMenuUseCaseProtocol
    
    private var contextMenuManager: ContextMenuManager?

    init(
        uploadFilesUseCase: UploadPhotoAssetsUseCaseProtocol,
        devicePermissionUseCase: DevicePermissionRequestUseCaseProtocol,
        reachabilityUseCase: ReachabilityUseCaseProtocol,
        createContextMenuUseCase: CreateContextMenuUseCaseProtocol,
        router: FileUploadingRouter
    ) {
        self.uploadPhotoAssetsUseCase = uploadFilesUseCase
        self.devicePermissionUseCase = devicePermissionUseCase
        self.reachabilityUseCase = reachabilityUseCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.router = router
    }

    struct ViewState: HomeUploadingViewModelOutputs {
        var state: HomeUploadingViewState
        var networkReachable: Bool
        var contextMenu: UIMenu?
    }
}

extension HomeUploadingViewModel: UploadAddMenuDelegate {
    func uploadAddMenu(didSelect action: UploadAddAction) {
        switch action {
        case .chooseFromPhotos:
            didTapUploadFromPhotoAlbum()
        case .newTextFile:
            didTapUploadFromNewTextFile()
        case .scanDocument:
            didTapUploadFromDocumentScan()
        case .capture:
            didTapUploadFromCamera()
        case .importFrom:
            didTapUploadFromImports()
        default: break
        }
    }
    
    func showActionSheet(with actions: [ContextActionSheetAction]) {}
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

    enum Source: CaseIterable {
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
