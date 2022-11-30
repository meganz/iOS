import SwiftUI
import MEGADomain

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {
    override var zoomState: PhotoLibraryZoomState {
        willSet {
            zoomStateWillChange(to: newValue)
        }
    }
    
    override init(libraryViewModel: PhotoLibraryContentViewModel) {
        super.init(libraryViewModel: libraryViewModel)
        zoomState = PhotoLibraryZoomState(maximumScaleFactor: .thirteen)
        
        subscribeToLibraryChange()
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
    
    private func zoomStateWillChange(to newState: PhotoLibraryZoomState) {
        if newState.isSingleColumn || zoomState.isSingleColumn {
            photoCategoryList = libraryViewModel.library.photoDateSections(for: newState.scaleFactor)
        }
    }
}
