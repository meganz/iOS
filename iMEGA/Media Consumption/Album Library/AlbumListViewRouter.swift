import SwiftUI
import Combine

@available(iOS 14.0, *)
protocol AlbumListViewRouting {
    func cell(withCameraUploadNode node: NodeEntity?) -> AlbumCell
    func albumContent(for photo: NodeEntity?) -> AlbumContainerWrapper
}

@available(iOS 14.0, *)
struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    
    func cell(withCameraUploadNode node: NodeEntity?) -> AlbumCell {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let favouriteRepo = FavouriteNodesRepository(sdk: sdk)
        let thumbnailRepo = ThumbnailRepository.default
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        
        let thumbnailUsecase = ThumbnailUseCase(repository: thumbnailRepo)
        let albumContentsUseCase = AlbumContentsUseCase(albumContentsRepo: albumContentsRepo, favouriteRepo: favouriteRepo)
        
        let vm = AlbumCellViewModel(
            cameraUploadNode: node,
            thumbnailUseCase: thumbnailUsecase,
            albumContentsUseCase: albumContentsUseCase
        )
        
        return AlbumCell(viewModel: vm)
    }
    
    func albumContent(for album: NodeEntity?) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(albumNode: album)
    }
    
    func build() -> UIViewController {
        let vm = AlbumListViewModel(usecase: AlbumListUseCase(repository: AlbumRepository()))
        let content = AlbumListView(viewModel: vm, router: self)
        
        return UIHostingController(rootView: content)
    }
    
    func start() {}
}
