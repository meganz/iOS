import Foundation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPermissions
import MEGASwift

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
        saveToPhotoAlbumTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let isGranted = await isPhotosPermissionGranted()
            if isGranted {
                await handleAuthorized(node: node)
            } else {
                error = .photos
                notifyUpdate?(outputs)
            }
        }
    }
    
    @MainActor
    private func isPhotosPermissionGranted() async -> Bool {
        await withAsyncValue { @Sendable [permissionHandler] completion in
            permissionHandler.photosPermissionWithCompletionHandler { isGranted in
                completion(.success(isGranted))
            }
        }
    }
    
    @MainActor
    private func handleAuthorized(node: NodeEntity) async {
        transferWidgetResponder?.bringProgressToFrontKeyWindowIfNeeded()
        
        do {
            try await saveMediaToPhotosUseCase.saveToPhotos(nodes: [node])
        } catch {
            if let errorEntity = error as? SaveMediaToPhotosErrorEntity,
               errorEntity != .cancelled {
                
                analyticsEventUseCase.sendAnalyticsEvent(.download(.saveToPhotos))
                
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        MEGAAssets.UIImage.saveToPhotos,
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
    
    private(set) var saveToPhotoAlbumTask: Task<Void, any Error>?
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
    
    deinit {
        saveToPhotoAlbumTask?.cancel()
        toggleFavouriteTask?.cancel()
    }
}

// MARK: - View Error

enum HomeRecentActionError: Error {
    case noPhotoAlbumAccess
}
