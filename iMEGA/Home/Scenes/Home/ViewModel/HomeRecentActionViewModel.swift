import Foundation
import MEGADomain
import MEGAPermissions
import MEGASDKRepo

protocol HomeRecentActionViewModelInputs: AnyObject {
    
    func saveToPhotoAlbum(of node: NodeEntity)
    
    func toggleFavourite(of node: NodeEntity)
}

protocol HomeRecentActionViewModelOutputs {
    
    var error: DevicePermissionDeniedError? { get }
}

protocol HomeRecentActionViewModelType {
    
    var inputs: any HomeRecentActionViewModelInputs { get }
    
    var outputs: any HomeRecentActionViewModelOutputs { get }
    
    var notifyUpdate: ((any HomeRecentActionViewModelOutputs) -> Void)? { get set }
}

final class HomeRecentActionViewModel:
    HomeRecentActionViewModelType,
    HomeRecentActionViewModelInputs,
    HomeRecentActionViewModelOutputs {
    
    // MARK: - HomeRecentActionViewModelInputs
    func saveToPhotoAlbum(of node: NodeEntity) {
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            if granted {
                handleAuthorized(node: node)
            } else {
                error = .photos
                notifyUpdate?(outputs)
            }
        }
    }
    
    private func handleAuthorized(node: NodeEntity) {
        transferWidgetResponder?.bringProgressToFrontKeyWindowIfNeeded()
        
        Task { @MainActor in
            do {
                try await saveMediaToPhotosUseCase.saveToPhotos(nodes: [node])
            } catch {
                if let errorEntity = error as? SaveMediaToPhotosErrorEntity,
                    errorEntity != .cancelled {
                    
                    analyticsEventUseCase.sendAnalyticsEvent(.download(.saveToPhotos))
                    
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        UIImage.saveToPhotos,
                        status: error.localizedDescription
                    )
                }
            }
        }
    }
    
    func toggleFavourite(of node: NodeEntity) {
        toggleFavouriteTask = Task {
            try await node.isFavourite
                ? nodeFavouriteActionUseCase.unFavourite(node: node)
                : nodeFavouriteActionUseCase.favourite(node: node)
        }
    }
    
    // MARK: - Task
    
    private(set) var toggleFavouriteTask: Task<Void, any Error>?
    
    // MARK: - HomeRecentActionViewModelOutputs
    
    var error: DevicePermissionDeniedError?
    
    // MARK: - HomeRecentActionViewModelType
    
    var inputs: any HomeRecentActionViewModelInputs { self }
    
    var outputs: any HomeRecentActionViewModelOutputs { self }
    
    var notifyUpdate: ((any HomeRecentActionViewModelOutputs) -> Void)?
    
    // MARK: - Use Cases
    
    private let permissionHandler: any DevicePermissionsHandling
    
    private let nodeFavouriteActionUseCase: any NodeFavouriteActionUseCaseProtocol
    
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    
    private weak var transferWidgetResponder: (any TransferWidgetResponderProtocol)?
    
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    
    init(
        permissionHandler: some DevicePermissionsHandling,
        nodeFavouriteActionUseCase: some NodeFavouriteActionUseCaseProtocol,
        saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol,
        transferWidgetResponder: (some TransferWidgetResponderProtocol)?,
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol
    ) {
        self.permissionHandler = permissionHandler
        self.nodeFavouriteActionUseCase = nodeFavouriteActionUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
        self.transferWidgetResponder = transferWidgetResponder
        self.analyticsEventUseCase = analyticsEventUseCase
    }
}

// MARK: - View Error

enum HomeRecentActionError: Error {
    case noPhotoAlbumAccess
}
