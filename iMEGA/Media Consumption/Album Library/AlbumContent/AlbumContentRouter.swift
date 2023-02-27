import UIKit
import SwiftUI
import MEGADomain
import MEGAPresentation

protocol AlbumContentRouting: Routing {
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void)
}

struct AlbumContentRouter: AlbumContentRouting {
    private weak var navigationController: UINavigationController?
    private let album: AlbumEntity
    private let newAlbumPhotos: [NodeEntity]?
        
    init(navigationController: UINavigationController?, album: AlbumEntity, newAlbumPhotos: [NodeEntity]?) {
        self.navigationController = navigationController
        self.album = album
        self.newAlbumPhotos = newAlbumPhotos
    }
    
    func build() -> UIViewController {
        let albumContentsUpdateRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let filesSearchRepo = FilesSearchRepository.newRepo
        let userAlbumRepo = UserAlbumRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsUpdateRepo,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: filesSearchRepo,
            userAlbumRepo: userAlbumRepo
        )
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: PhotoLibraryRepository.newRepo,
                                                      searchRepository: FilesSearchRepository.newRepo)
        let viewModel = AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            mediaUseCase: mediaUseCase,
            albumContentModificationUseCase: AlbumContentModificationUseCase(userAlbumRepo: userAlbumRepo),
            photoLibraryUseCase: photoLibraryUseCase,
            router: self,
            newAlbumPhotosToAdd: newAlbumPhotos)
        return AlbumContentViewController(viewModel: viewModel)
    }
    
    @MainActor
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        let photoLibraryRepository = PhotoLibraryRepository.newRepo
        let fileSearchRepository = FilesSearchRepository.newRepo
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                                      searchRepository: fileSearchRepository)
        let viewModel = AlbumContentPickerViewModel(album: album,
                                                    photoLibraryUseCase: photoLibraryUseCase,
                                                    completion: completion)
        let content = AlbumContentPickerView(viewModel: viewModel)
        navigationController?.present(UIHostingController(rootView: content), animated: true)
    }
    
    func start() {}
}
