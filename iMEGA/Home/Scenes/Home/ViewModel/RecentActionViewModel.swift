import Foundation

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
    HomeRecentActionViewModelOutputs
{
    // MARK: - HomeRecentActionViewModelInputs

    func saveToPhotoAlbum(of node: MEGANode) {
        devicePermissionUseCase.getAlbumAuthorizationStatus { [weak self] photoAuthorization in
            switch photoAuthorization {
            case .authorized:
                node.mnz_saveToPhotos(withApi: MEGASdkManager.sharedMEGASdk())
            default:
                guard let self = self else { return }
                self.error = .photos
                self.notifyUpdate?(self.outputs)
            }
        }
    }

    func toggleFavourite(of node: MEGANode) {
        let isFavourite = nodeFavouriteActionUseCase.isNodeFavourite(nodeHandle: node.handle)

        switch isFavourite {
        case .failure:
            break
        case .success(let isFavourite):
            isFavourite
                ? nodeFavouriteActionUseCase.removeNodeFromFavourite(nodeHandle: node.handle, completion: { _ in })
                : nodeFavouriteActionUseCase.addNodeToFavourite(nodeHandle: node.handle, completion: { _ in })
        }

    }

    // MARK: - HomeRecentActionViewModelOutputs

    var error: DevicePermissionDeniedError?

    // MARK: - HomeRecentActionViewModelType

    var inputs: HomeRecentActionViewModelInputs { self }

    var outputs: HomeRecentActionViewModelOutputs { self }

    var notifyUpdate: ((HomeRecentActionViewModelOutputs) -> Void)?

    // MARK: - Use Cases

    private let devicePermissionUseCase: DevicePermissionCheckingProtocol

    private let nodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol

    init(
        devicePermissionUseCase: DevicePermissionCheckingProtocol,
        nodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol
    ) {
        self.devicePermissionUseCase = devicePermissionUseCase
        self.nodeFavouriteActionUseCase = nodeFavouriteActionUseCase
    }
}

// MARK: - View Error

enum HomeRecentActionError: Error {
   case noPhotoAlbumAccess
}
