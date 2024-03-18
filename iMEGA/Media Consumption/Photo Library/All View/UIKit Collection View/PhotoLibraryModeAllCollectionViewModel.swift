import MEGADomain
import MEGAPresentation
import SwiftUI

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {
    
    private(set) lazy var photoZoomControlPositionTracker = PhotoZoomControlPositionTracker(
        shouldTrackScrollOffsetPublisher: $showEnableCameraUpload,
        baseOffset: 0)
    
    override init(libraryViewModel: PhotoLibraryContentViewModel,
                  preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        
        super.init(libraryViewModel: libraryViewModel, preferenceUseCase: preferenceUseCase)
        
        zoomState = PhotoLibraryZoomState(
            scaleFactor: libraryViewModel.configuration?.scaleFactor ?? zoomState.scaleFactor,
            maximumScaleFactor: .thirteen
        )
        
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
