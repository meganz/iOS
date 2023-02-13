import UIKit
import MEGADomain

struct AlbumContentRouter: Routing {
    private let album: AlbumEntity
    private let messageForNewAlbum: String?
    
    init(album: AlbumEntity, messageForNewAlbum: String?) {
        self.album = album
        self.messageForNewAlbum = messageForNewAlbum
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        let filesSearchRepo = FilesSearchRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: UserAlbumRepository.newRepo
        )
        
        let viewModel = AlbumContentViewModel(
            album: album,
            messageForNewAlbum: self.messageForNewAlbum,
            albumContentsUseCase: albumContentsUseCase,
            mediaUseCase: mediaUseCase,
            router: self)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    func start() {}
}
