import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGADomain
import SwiftUI

final class AlbumCoverPickerPhotoCellViewModel: PhotoCellViewModel {
    
    let photoSelection: AlbumCoverPickerPhotoSelection
    
    private let albumPhoto: AlbumPhotoEntity
    
    init(albumPhoto: AlbumPhotoEntity,
         photoSelection: AlbumCoverPickerPhotoSelection,
         viewModel: PhotoLibraryModeAllViewModel,
         thumbnailLoader: some ThumbnailLoaderProtocol,
         nodeUseCase: some NodeUseCaseProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol) {
        self.albumPhoto = albumPhoto
        self.photoSelection = photoSelection
        
        super.init(photo: albumPhoto.photo,
                   viewModel: viewModel,
                   thumbnailLoader: thumbnailLoader,
                   nodeUseCase: nodeUseCase,
                   sensitiveNodeUseCase: sensitiveNodeUseCase)
        
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
