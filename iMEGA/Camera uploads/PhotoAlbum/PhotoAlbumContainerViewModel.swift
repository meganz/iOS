import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPreference
import SwiftUI

@MainActor
final class PhotoAlbumContainerViewModel: ObservableObject {
    @Published var editMode: EditMode = .inactive {
        willSet {
            showToolbar = newValue == .active
        }
    }
    @Published var shouldShowSelectBarButton = false
    @Published var isAlbumsSelected = false
    @Published var showDeleteAlbumAlert = false
    @Published var isExportedAlbumSelected: Bool = false
    @Published var isOnlyExportedAlbumsSelected = false 
    @Published var showShareAlbumLinks = false
    @Published var showRemoveAlbumLinksAlert = false
    @Published private(set) var showToolbar = false
    @Published var disableSelectBarButton = false
    @PreferenceWrapper(key: PreferenceKeyEntity.shouldShowCameraUploadsEnabledSnackbar, defaultValue: false)
    private var shouldShowCameraUploadsEnabledSnackbar: Bool

    let showSnackBarSubject = PassthroughSubject<String, Never>()

    private let tracker: any AnalyticsTracking
    private let overDiskQuotaChecker: any OverDiskQuotaChecking

    init(
        tracker: some AnalyticsTracking,
        overDiskQuotaChecker: some OverDiskQuotaChecking,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.tracker = tracker
        self.overDiskQuotaChecker = overDiskQuotaChecker
        $shouldShowCameraUploadsEnabledSnackbar.useCase = preferenceUseCase
    }
    
    func didAppear() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoScreenEvent)
        checkShouldShowCamerUploadsEnabledSnackBar()
    }
    
    func shareLinksTapped() {
        tracker.trackAnalyticsEvent(with: DIContainer.albumListShareLinkMenuItemEvent)
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showShareAlbumLinks = true
    }
    
    func removeLinksTapped() {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showRemoveAlbumLinksAlert.toggle()
    }
    
    func deleteAlbumsTapped() {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showDeleteAlbumAlert.toggle()
    }

    private func checkShouldShowCamerUploadsEnabledSnackBar() {
        guard shouldShowCameraUploadsEnabledSnackbar else { return }
        showSnackBarSubject.send(Strings.Localizable.cameraUploadsEnabled)
        showSnackBarSubject.send(completion: .finished)
        shouldShowCameraUploadsEnabledSnackbar = false
    }
}
