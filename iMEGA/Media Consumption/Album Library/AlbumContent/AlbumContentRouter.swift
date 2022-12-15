import UIKit
import MEGADomain

struct AlbumContentRouter: Routing {
    private let album: AlbumEntity
    
    init(album: AlbumEntity) {
        self.album = album
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        
        let favouriteRepo = FavouriteNodesRepository.newRepo
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        let photoUseCase = PhotoLibraryUseCase(
            photosRepository: PhotoLibraryRepository.newRepo,
            searchRepository: SDKFilesSearchRepository.newRepo
        )
        
        let mediaUseCase = MediaUseCase()
        
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            favouriteRepo: favouriteRepo,
            photoUseCase: photoUseCase,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: FileSearchRepository.newRepo
        )
        
        let viewModel = AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            router: self)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    func start() {}
}
