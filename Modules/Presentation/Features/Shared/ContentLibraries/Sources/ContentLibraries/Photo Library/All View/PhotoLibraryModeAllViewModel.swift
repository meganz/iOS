import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGARepo

public class PhotoLibraryModeAllViewModel: PhotoLibraryModeViewModel<PhotoDateSection> {
    @Published var zoomState = PhotoLibraryZoomState()
    @Published private(set) var showEnableCameraUpload: Bool = false

    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private let invalidateCameraUploadEnabledSettingPassthroughSubject = PassthroughSubject<Void, Never>()
    
    public init(libraryViewModel: PhotoLibraryContentViewModel,
                preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        
        super.init(libraryViewModel: libraryViewModel)
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        photoCategoryList = libraryViewModel.library.photoMonthSections
        
        subscribeToLibraryChanges()
        subscribeToZoomScaleFactorChange()
    }
    
    public func invalidateCameraUploadEnabledSetting() {
        invalidateCameraUploadEnabledSettingPassthroughSubject.send()
    }
    
    private func subscribeToLibraryChanges() {
        if libraryViewModel.contentMode == .library {
            Publishers.Merge(
                libraryViewModel.$library.map { _ in () },
                invalidateCameraUploadEnabledSettingPassthroughSubject
            )
            .map { [weak self] _ in
                !(self?.isCameraUploadsEnabled ?? true)
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
