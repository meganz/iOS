import UIKit
import MEGADomain

@available(iOS 14.0, *)
struct AlbumContentRouter: Routing {
    private let cameraUploadNode: NodeEntity?
    private let album: AlbumEntity?
    
    init(cameraUploadNode: NodeEntity?, album: AlbumEntity?) {
        self.cameraUploadNode = cameraUploadNode
        self.album = album
    }
    
    private var isFavouriteAlbum: Bool {
        cameraUploadNode != nil && album == nil
    }
    
    private var albumName: String {
        isFavouriteAlbum ? Strings.Localizable.CameraUploads.Albums.Favourites.title : album?.name ?? ""
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
        
        let viewModel = AlbumContentViewModel(cameraUploadNode: cameraUploadNode,
                                              album: album,
                                              albumName: albumName,
                                              albumContentsUseCase: albumContentsUseCase,
                                              router: self)
        let vc = AlbumContentViewController(viewModel: viewModel)
        
        return vc
    }
    
    func start() {}
}
