import SwiftUI
import MEGADomain

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        zoomState = PhotoLibraryZoomState(maximumScaleFactor: .thirteen)
        
        subscribeToLibraryChange()
        subscribeToZoomStateChange()
    }
    
    // MARK: Private
    private func subscribeToLibraryChange() {
        libraryViewModel
            .$library
            .dropFirst()
            .map { [weak self] in
                $0.photoDateSections(for: self?.zoomState.scaleFactor ?? PhotoLibraryZoomState.defaultScaleFactor)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$photoCategoryList)
    }
    
    private func subscribeToZoomStateChange() {
        $zoomState
            .dropFirst()
            .sink { [weak self] in
                guard let self else { return }
                
                if $0.isSingleColumn || self.zoomState.isSingleColumn == true {
                    self.photoCategoryList = self.libraryViewModel.library.photoDateSections(for: $0.scaleFactor)
                }
            }
            .store(in: &subscriptions)
    }
}
