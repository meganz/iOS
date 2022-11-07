import Foundation
import MEGADomain

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
                guard let self = self else { return }
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                self.saveMediaToPhotosUseCase.saveToPhotos(node: node.toNodeEntity()) { result in
                    if case let .failure(error) = result, error != .cancelled {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
                    }
                }
                
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
            if isFavourite {
                nodeFavouriteActionUseCase.removeNodeFromFavourite(nodeHandle: node.handle) { (result) in
                    switch result {
                    case .success():
                        if #available(iOS 14.0, *) {
                            QuickAccessWidgetManager().deleteFavouriteItem(for: node)
                        }
                    case .failure(_):
                        break
                    }
                }
            } else {
                nodeFavouriteActionUseCase.addNodeToFavourite(nodeHandle: node.handle) { (result) in
                    switch result {
                    case .success():
                        if #available(iOS 14.0, *) {
                            QuickAccessWidgetManager().insertFavouriteItem(for: node)
                        }
                    case .failure(_):
                        break
                    }
                }
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

    private let devicePermissionUseCase: DevicePermissionCheckingProtocol

    private let nodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol

    private let saveMediaToPhotosUseCase: SaveMediaToPhotosUseCaseProtocol

    init(
        devicePermissionUseCase: DevicePermissionCheckingProtocol,
        nodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol,
        saveMediaToPhotosUseCase: SaveMediaToPhotosUseCaseProtocol
    ) {
        self.devicePermissionUseCase = devicePermissionUseCase
        self.nodeFavouriteActionUseCase = nodeFavouriteActionUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
    }
    
}

// MARK: - View Error

enum HomeRecentActionError: Error {
   case noPhotoAlbumAccess
}
