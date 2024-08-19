import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPermissions
import MEGAPresentation

protocol HomeUploadingViewModelInputs {

    func viewIsReady()
}

protocol HomeUploadingViewModelOutputs {

    var state: HomeUploadingViewState { get }

    var networkReachable: Bool { get }
    
    var contextMenu: UIMenu? { get }
}

protocol HomeUploadingViewModelType {

    var inputs: any HomeUploadingViewModelInputs { get }

    var outputs: any HomeUploadingViewModelOutputs { get }

    var notifyUpdate: ((any HomeUploadingViewModelOutputs) -> Void)? { get set }
}

final class HomeUploadingViewModel: HomeUploadingViewModelType, HomeUploadingViewModelInputs {
    private var cancellable: Set<AnyCancellable> = []
    
    // MARK: - HomeUploadingViewModelInputs

    func viewIsReady() {
        self.contextMenuManager = ContextMenuManager(
            uploadAddMenuDelegate: self,
            createContextMenuUseCase: createContextMenuUseCase
        )
        notifyUpdate?(self.outputs)
        
        networkMonitorUseCase.networkPathChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.notifyUpdate?(self.outputs)
            }
            .store(in: &cancellable)
    }

    func didTapUploadFromPhotoAlbum() {
        tracker.trackAnalyticsEvent(with: HomeChooseFromPhotosMenuToolbarEvent())
        
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            if granted {
                let selectionHandler: (([PHAsset], MEGANode) -> Void) = { [weak self] assets, targetNode in
                    guard let self else { return }
                    self.uploadFiles(fromPhotoAssets: assets, to: targetNode)
                }
                self.router.upload(from: .album(selectionHandler))
            } else {
                self.error = .photos
                self.notifyUpdate?(self.outputs)
            }
        }
    }
    
    func didTapUploadFromNewTextFile() {
        router.upload(from: .textFile)
    }

    func didTapUploadFromCamera() {
        permissionHandler.requestVideoPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.router.upload(from: .camera)
            } else {
                self.error = .video
                self.notifyUpdate?(self.outputs)
            }
        }
    }

    func didTapUploadFromImports() {
        tracker.trackAnalyticsEvent(with: HomeImportFromFilesMenuToolbarEvent())
        
        router.upload(from: .imports)
    }

    func didTapUploadFromDocumentScan() {
        permissionHandler.requestVideoPermission { [weak self] granted in
            guard let self else { return }
            if granted {
                self.router.upload(from: .documentScan)
            } else {
                self.error = .video
                self.notifyUpdate?(self.outputs)
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

    var inputs: any HomeUploadingViewModelInputs { self }

    var outputs: any HomeUploadingViewModelOutputs {
        let networkReachable = networkMonitorUseCase.isConnected()
        let cmConfigEntity = CMConfigEntity(menuType: .menu(type: .uploadAdd), isHome: true)
        if let error = error {
            return ViewState(
                state: .permissionDenied(error),
                networkReachable: networkReachable,
                contextMenu: contextMenuManager?.contextMenu(with: cmConfigEntity)
            )
        }
        
        return ViewState(state: .normal,
                         networkReachable: networkReachable,
                         contextMenu: contextMenuManager?.contextMenu(with: cmConfigEntity)
        )
    }

    var notifyUpdate: ((any HomeUploadingViewModelOutputs) -> Void)?

    // MARK: - Router

    private let router: FileUploadingRouter

    // MARK: - Use Cases

    private let uploadPhotoAssetsUseCase: any UploadPhotoAssetsUseCaseProtocol

    private let permissionHandler: any DevicePermissionsHandling

    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    
    private let createContextMenuUseCase: any CreateContextMenuUseCaseProtocol
    
    private let tracker: any AnalyticsTracking
    
    private var contextMenuManager: ContextMenuManager?

    init(
        uploadFilesUseCase: any UploadPhotoAssetsUseCaseProtocol,
        permissionHandler: some DevicePermissionsHandling,
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol,
        createContextMenuUseCase: any CreateContextMenuUseCaseProtocol,
        tracker: some AnalyticsTracking,
        router: FileUploadingRouter
    ) {
        self.uploadPhotoAssetsUseCase = uploadFilesUseCase
        self.permissionHandler = permissionHandler
        self.networkMonitorUseCase = networkMonitorUseCase
        self.createContextMenuUseCase = createContextMenuUseCase
        self.tracker = tracker
        self.router = router
    }

    struct ViewState: HomeUploadingViewModelOutputs {
        var state: HomeUploadingViewState
        var networkReachable: Bool
        var contextMenu: UIMenu?
    }
}

extension HomeUploadingViewModel: UploadAddMenuDelegate {
    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
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
        case .photos: return UIImage.saveToPhotos
        case .textFile: return UIImage.textfile
        case .capture: return UIImage.capture
        case .imports: return UIImage.import
        case .documentScan: return UIImage.scanDocument
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
