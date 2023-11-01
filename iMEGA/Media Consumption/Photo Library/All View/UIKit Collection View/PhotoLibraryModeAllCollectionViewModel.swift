import MEGADomain
import MEGAPresentation
import SwiftUI

final class PhotoLibraryModeAllCollectionViewModel: PhotoLibraryModeAllViewModel {
    let contentMode: PhotoLibraryContentMode
    @Published private(set) var showEnableCameraUpload: Bool = false
    
    private(set) lazy var photoZoomControlPositionTracker = PhotoZoomControlPositionTracker(
        shouldTrackScrollOffsetPublisher: $showEnableCameraUpload,
        baseOffset: 0)
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool

    init(libraryViewModel: PhotoLibraryContentViewModel,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.contentMode = libraryViewModel.contentMode
        self.featureFlagProvider = featureFlagProvider
        
        super.init(libraryViewModel: libraryViewModel)
        
        $isCameraUploadsEnabled.useCase = preferenceUseCase
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
        
        if libraryViewModel.contentMode == .library {
            libraryViewModel
                .$library
                .map { [weak self] _ in
                    guard let self else {
                        return false
                    }
                    return featureFlagProvider.isFeatureFlagEnabled(for: .timelineCameraUploadStatus) && !isCameraUploadsEnabled
                }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .assign(to: &$showEnableCameraUpload)
        }
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
