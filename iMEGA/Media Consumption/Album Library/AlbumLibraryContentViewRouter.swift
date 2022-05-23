import SwiftUI
import Combine

@available(iOS 14.0, *)
protocol AlbumLibraryContentViewRouting {
    func cell(for album: NodeEntity) -> AlbumCell
    func albumContent(for photo: NodeEntity) -> AlbumContainerWrapper
}

@available(iOS 14.0, *)
struct AlbumLibraryContentViewRouter: AlbumLibraryContentViewRouting, Routing {
    
    func cell(for album: NodeEntity) -> AlbumCell {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let favouriteRepo = FavouriteNodesRepository(sdk: sdk)
        let thumbnailRepo = ThumbnailRepository.default
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        
        let favouriteUsecase = FavouriteNodesUseCase(repo: favouriteRepo)
        let thumbnailUsecase = ThumbnailUseCase(repository: thumbnailRepo)
        let albumContentsUseCase = AlbumContentsUseCase(albumContentsRepo: albumContentsRepo)
        
        let vm = AlbumCellViewModel(
            album: album,
            favouriteUseCase: favouriteUsecase,
            thumbnailUseCase: thumbnailUsecase,
            albumContentsUseCase: albumContentsUseCase
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContent(for album: NodeEntity) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(albumNode: album)
    }
    
    func build() -> UIViewController {
        let vm = AlbumLibraryContentViewModel(usecase: AlbumUseCase(repository: AlbumRepository()))
        let content = AlbumLibraryContentView(viewModel: vm, router: self)
        
        return UIHostingController(rootView: content)
    }
    
    func start() {}
}
