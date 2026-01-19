import MEGAAppPresentation
import MEGADomain
import MEGAPreference
import SwiftUI

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {

    private(set) lazy var photoZoomControlPositionTracker = PhotoZoomControlPositionTracker(
        shouldTrackScrollOffsetPublisher: $bannerType.map { $0 != nil },
        baseOffset: 0)

    private let isMediaRevampEnabled: Bool

    init(
        libraryViewModel: PhotoLibraryContentViewModel,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.isMediaRevampEnabled = configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
        super.init(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: preferenceUseCase,
            configuration: configuration
        )

        subscribeToLibraryChange()
        subscribeToZoomStateChange()

        let isAlbumMode = libraryViewModel.contentMode == .album
        if isAlbumMode && isMediaRevampEnabled && !zoomState.isSingleColumn {
            photoCategoryList = [libraryViewModel.library.photoMasonrySection]
        }
    }
    
    // MARK: Private
    private func subscribeToLibraryChange() {
        let isAlbumMode = libraryViewModel.contentMode == .album

        libraryViewModel
            .$library
            .dropFirst()
            .map { [weak self] library in
                guard let self else { return [] }

                // Only use masonry layout for album mode when media revamp is enabled
                if isAlbumMode && self.isMediaRevampEnabled && !self.zoomState.isSingleColumn {
                    return [library.photoMasonrySection]
                }
                return library.photoDateSections(for: self.zoomState.scaleFactor)
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
