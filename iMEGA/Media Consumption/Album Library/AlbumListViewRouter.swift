import SwiftUI
import MEGADomain

protocol AlbumListViewRouting {
    func cell(album: AlbumEntity) -> AlbumCell
    func albumContainer(album: AlbumEntity) -> AlbumContainerWrapper
}

struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    
    func cell(album: AlbumEntity) -> AlbumCell {
        let vm = AlbumCellViewModel(
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            album: album
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContainer(album: AlbumEntity) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(album: album)
    }
    
    func build() -> UIViewController {
        let vm = AlbumListViewModel(
            usecase: AlbumListUseCase(
                albumRepository: AlbumRepository.newRepo,
                userAlbumRepository: UserAlbumRepository.newRepo,
                fileSearchRepository: FileSearchRepository.newRepo,
                mediaUseCase: MediaUseCase()
            )
        )
        
        let alertVm = TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Album.Create.Alert.title,
                                              invalidTextTitle: Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters),
                                              placeholderText: Strings.Localizable.CameraUploads.Album.Create.Alert.placeholder,
                                              affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                              message: nil) { newAlbumName in
            Task { await vm.createUserAlbum(with: newAlbumName) }
        }
        
        let content = AlbumListView(viewModel: vm,
                                    createAlbumCellViewModel: CreateAlbumCellViewModel(),
                                    alertViewModel: alertVm,
                                    router: self)
        
        return UIHostingController(rootView: content)
    }
    func start() {}
}
