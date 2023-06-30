import Foundation
import MEGAData
import MEGADomain
import MEGAPermissions

protocol HomeRecentActionViewModelInputs {

    func saveToPhotoAlbum(of node: MEGANode)

    func toggleFavourite(of node: MEGANode)
}

protocol HomeRecentActionViewModelOutputs {

    var error: DevicePermissionDeniedError? { get }
}

protocol HomeRecentActionViewModelType {

    var inputs: HomeRecentActionViewModelInputs { get }

    var outputs: HomeRecentActionViewModelOutputs { get }

    var notifyUpdate: ((HomeRecentActionViewModelOutputs) -> Void)? { get set }
}

final class HomeRecentActionViewModel:
    HomeRecentActionViewModelType,
    HomeRecentActionViewModelInputs,
    HomeRecentActionViewModelOutputs {
    // MARK: - HomeRecentActionViewModelInputs

    func saveToPhotoAlbum(of node: MEGANode) {
        
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            if granted {
                self.handleAuthorized(node: node)
            } else {
                self.error = .photos
                self.notifyUpdate?(self.outputs)
            }
        }
    }
    
    func handleAuthorized(node: MEGANode) {
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
        Task { @MainActor in
            do {
                try await self.saveMediaToPhotosUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
            } catch {
                if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                    AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo).sendAnalyticsEvent(.download(.saveToPhotos))
                    await SVProgressHUD.dismiss()
                    SVProgressHUD.show(
                        Asset.Images.NodeActions.saveToPhotos.image,
                        status: error.localizedDescription
                    )
                }
            }
            
        }
    }

    func toggleFavourite(of node: MEGANode) {
        if node.isFavourite {
            Task {
                try await nodeFavouriteActionUseCase.unFavourite(node: node.toNodeEntity())
                QuickAccessWidgetManager().deleteFavouriteItem(for: node)
            }
        } else {
            Task {
                try await nodeFavouriteActionUseCase.favourite(node: node.toNodeEntity())
                QuickAccessWidgetManager().insertFavouriteItem(for: node)
            }
        }
    }

    // MARK: - HomeRecentActionViewModelOutputs

    var error: DevicePermissionDeniedError?

    // MARK: - HomeRecentActionViewModelType

    var inputs: HomeRecentActionViewModelInputs { self }

    var outputs: HomeRecentActionViewModelOutputs { self }

    var notifyUpdate: ((HomeRecentActionViewModelOutputs) -> Void)?

    // MARK: - Use Cases

    private let permissionHandler: any DevicePermissionsHandling

    private let nodeFavouriteActionUseCase: any NodeFavouriteActionUseCaseProtocol

    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol

    init(
        permissionHandler: some DevicePermissionsHandling,
        nodeFavouriteActionUseCase: any NodeFavouriteActionUseCaseProtocol,
        saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    ) {
        self.permissionHandler = permissionHandler
        self.nodeFavouriteActionUseCase = nodeFavouriteActionUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
    }
    
}

// MARK: - View Error

enum HomeRecentActionError: Error {
   case noPhotoAlbumAccess
}
