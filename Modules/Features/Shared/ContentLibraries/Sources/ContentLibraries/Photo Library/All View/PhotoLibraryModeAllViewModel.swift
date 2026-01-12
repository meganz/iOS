import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGAPreference
import MEGARepo

public class PhotoLibraryModeAllViewModel: PhotoLibraryModeViewModel<PhotoDateSection> {
    @Published var zoomState: PhotoLibraryZoomState
    @Published private(set) var bannerType: PhotoLibraryBannerType?
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.lastEnableCameraUploadBannerDismissedDate, defaultValue: nil)
    private(set) var lastEnableCameraUploadBannerDismissedDate: Date?
    @PreferenceWrapper(key: PreferenceKeyEntity.limitedPhotoAccessBannerDismissedDate, defaultValue: nil)
    private(set) var limitedPhotoAccessBannerDismissedDate: Date?
    private let isMediaRevampEnabled: Bool
    private let devicePermissionHandler: any DevicePermissionsHandling
    private let updateBannerHeaderPassthroughSubject = PassthroughSubject<Void, Never>()
    private let bannerDismissCooldown: TimeInterval = .days(15)
    
    public init(
        libraryViewModel: PhotoLibraryContentViewModel,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        devicePermissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler(),
        configuration: ContentLibraries.Configuration = ContentLibraries.configuration
    ) {
        self.isMediaRevampEnabled = configuration.featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
        let supportedScaleFactors: [PhotoLibraryZoomState.ScaleFactor] = isMediaRevampEnabled
        ? [.one, .three, .five]
        : PhotoLibraryZoomState.ScaleFactor.allCases
        let maximumScaleFactor: PhotoLibraryZoomState.ScaleFactor = isMediaRevampEnabled ? .five : .thirteen
        
        self.zoomState = PhotoLibraryZoomState(
            scaleFactor: libraryViewModel.configuration?.scaleFactor ?? PhotoLibraryZoomState.defaultScaleFactor,
            maximumScaleFactor: maximumScaleFactor,
            supportedScaleFactors: supportedScaleFactors
        )
        self.devicePermissionHandler = devicePermissionHandler
        
        super.init(libraryViewModel: libraryViewModel)
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        $lastEnableCameraUploadBannerDismissedDate.useCase = preferenceUseCase
        $limitedPhotoAccessBannerDismissedDate.useCase = preferenceUseCase
        photoCategoryList = libraryViewModel.library.photoMonthSections
        
        subscribeToLibraryChanges()
        subscribeToZoomScaleFactorChange()
    }
    
    private var cameraUploadHeaderType: PhotoLibraryBannerType? {
        guard isMediaRevampEnabled else {
            return isCameraUploadsEnabled ? nil : .enableCameraUploads
        }
        guard !isCameraUploadsEnabled else {
            return cameraUploadEnabledBannerType
        }
        guard let lastDismissedDate = lastEnableCameraUploadBannerDismissedDate else {
            return .enableCameraUploads
        }
        
        return if Date.now.timeIntervalSince(lastDismissedDate) > bannerDismissCooldown {
            .enableCameraUploads
        } else {
            nil
        }
    }
    
    private var cameraUploadEnabledBannerType: PhotoLibraryBannerType? {
        guard devicePermissionHandler.photoLibraryAuthorizationStatus == .limited else {
            return nil
        }
        guard let lastDismissedDate = limitedPhotoAccessBannerDismissedDate else {
            return .limitedPermissions
        }
        return if Date.now.timeIntervalSince(lastDismissedDate) > bannerDismissCooldown {
            .limitedPermissions
        } else {
            nil
        }
    }
    
    public func invalidateCameraUploadEnabledSetting() {
        updateBannerHeaderPassthroughSubject.send()
    }
    
    func dismissEnableCameraUploadBanner() {
        lastEnableCameraUploadBannerDismissedDate = Date.now
        invalidateCameraUploadEnabledSetting()
    }
    
    func dismissLimitedAccessBanner() {
        limitedPhotoAccessBannerDismissedDate = Date.now
        updateBannerHeaderPassthroughSubject.send()
    }
    
    private func subscribeToLibraryChanges() {
        if libraryViewModel.contentMode == .library {
            Publishers.Merge(
                libraryViewModel.$library.map { _ in () },
                updateBannerHeaderPassthroughSubject
            )
            .map { [weak self] _ in
                self?.cameraUploadHeaderType
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$bannerType)
        }
    }
    
    private func subscribeToZoomScaleFactorChange() {
        $zoomState.map { $0.scaleFactor == .thirteen }
            .removeDuplicates()
            .assign(to: &libraryViewModel.selection.$isHidden)
    }
}

extension PhotoLibraryModeAllViewModel {
    var isEditing: Bool {
        libraryViewModel.selection.editMode.isEditing
    }
}

private extension TimeInterval {
    static func days(_ value: Double) -> TimeInterval {
        value * 24 * 60 * 60
    }
}
