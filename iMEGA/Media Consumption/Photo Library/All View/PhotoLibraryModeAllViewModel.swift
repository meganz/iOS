import Combine
import Foundation
import MEGADomain
import MEGAPresentation

class PhotoLibraryModeAllViewModel: PhotoLibraryModeViewModel<PhotoDateSection> {
    @Published var zoomState = PhotoLibraryZoomState()
    @Published private(set) var showEnableCameraUpload: Bool = false

    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let invalidateCameraUploadEnabledSettingPassthroughSubject = PassthroughSubject<Void, Never>()
    
    init(libraryViewModel: PhotoLibraryContentViewModel,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        
        self.featureFlagProvider = featureFlagProvider

        super.init(libraryViewModel: libraryViewModel)
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        photoCategoryList = libraryViewModel.library.photoMonthSections
        
        subscribeToLibraryChanges()
        subscribeToZoomScaleFactorChange()
    }
    
    func invalidateCameraUploadEnabledSetting() {
        invalidateCameraUploadEnabledSettingPassthroughSubject.send()
    }
    
    private func subscribeToLibraryChanges() {
        if libraryViewModel.contentMode == .library {
            Publishers.Merge(
                libraryViewModel.$library.map { _ in () },
                invalidateCameraUploadEnabledSettingPassthroughSubject
            )
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
    
    private func subscribeToZoomScaleFactorChange() {
        $zoomState.map { $0.scaleFactor == .thirteen }
            .removeDuplicates()
            .assign(to: &libraryViewModel.selection.$isHidden)
    }
}
