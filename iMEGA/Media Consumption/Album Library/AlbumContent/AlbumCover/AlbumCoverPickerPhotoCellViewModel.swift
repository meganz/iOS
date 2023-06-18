import Combine
import SwiftUI
import MEGADomain

final class AlbumCoverPickerPhotoCellViewModel: PhotoCellViewModel {
    
    let photoSelection: AlbumCoverPickerPhotoSelection
    
    private let albumPhoto: AlbumPhotoEntity
    
    init(albumPhoto: AlbumPhotoEntity,
         photoSelection: AlbumCoverPickerPhotoSelection,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailUseCase: any ThumbnailUseCaseProtocol) {
        self.albumPhoto = albumPhoto
        self.photoSelection = photoSelection
        
        super.init(photo: albumPhoto.photo, viewModel: viewModel, thumbnailUseCase: thumbnailUseCase)
        
        setupSubscription()
    }
    
    func onPhotoSelect() {
        photoSelection.selectedPhoto = albumPhoto
    }
    
    func setupSubscription() {
        photoSelection.$selectedPhoto
            .map { [weak self] in $0 == self?.albumPhoto }
            .assign(to: &$isSelected)
    }
}
