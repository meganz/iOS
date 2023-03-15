import Combine
import SwiftUI
import MEGADomain

final class AlbumCoverPickerPhotoCellViewModel: PhotoCellViewModel {
    
    let photoSelection: AlbumCoverPickerPhotoSelection
    
    private let photo: NodeEntity
    
    init(photo: NodeEntity,
         photoSelection: AlbumCoverPickerPhotoSelection,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailUseCase: ThumbnailUseCaseProtocol,
         mediaUseCase: MediaUseCaseProtocol) {
        self.photo = photo
        self.photoSelection = photoSelection
        
        super.init(photo: photo, viewModel: viewModel, thumbnailUseCase: thumbnailUseCase, mediaUseCase: mediaUseCase)
        
        setupSubscription()
    }
    
    func onPhotoSelect() {
        photoSelection.selectedPhoto = photo
    }
    
    func setupSubscription() {
        photoSelection.$selectedPhoto
            .map { [weak self] in $0 == self?.photo }
            .assign(to: &$isSelected)
    }
}
