import MEGAAppPresentation
import MEGADomain
import MEGAPreference
import SwiftUI

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {

    private(set) lazy var photoZoomControlPositionTracker = PhotoZoomControlPositionTracker(
        shouldTrackScrollOffsetPublisher: $bannerType.map { $0 != nil },
        baseOffset: 0)

    private let isMediaRevampEnabled: Bool

    /// Pre-revamp behaviour kept the +/- zoom control in the top-trailing corner. The
    /// rolled-back Album also needs it back, even while `iosMediaRevamp` is still on.
    var shouldShowZoomControl: Bool {
        let isAlbumRollback = libraryViewModel.contentMode == .album && !AlbumLayoutGate.isMasonryLayoutEnabled
        return !isMediaRevampEnabled || isAlbumRollback
    }

    init(
        libraryViewModel: PhotoLibraryContentViewModel,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.isMediaRevampEnabled = configuration.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaRevamp)
        super.init(
            libraryViewModel: libraryViewModel,
            preferenceUseCase: preferenceUseCase,
            configuration: configuration
        )

        subscribeToLibraryChange()
        subscribeToZoomStateChange()

        let isAlbumMode = libraryViewModel.contentMode == .album
        if isAlbumMode && AlbumLayoutGate.isMasonryLayoutEnabled && !zoomState.isSingleColumn {
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

                if isAlbumMode && AlbumLayoutGate.isMasonryLayoutEnabled && !self.zoomState.isSingleColumn {
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
