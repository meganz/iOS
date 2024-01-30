import Combine
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGASwift

final class CameraUploadStatusBannerViewModel: ObservableObject {
    
    @Published var cameraUploadStatusShown = false
    @Published private(set) var cameraUploadBannerStatusViewState: CameraUploadBannerStatusViewStates = .uploadCompleted
    @Published var showPhotoPermissionAlert = false
    
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var monitorCameraUploadBannerStatusProvider: MonitorCameraUploadBannerStatusProvider
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.featureFlagProvider = featureFlagProvider
        self.monitorCameraUploadBannerStatusProvider = MonitorCameraUploadBannerStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler)
        
        subscribeToHandleAutoPresentation()
    }
        
    @MainActor
    func monitorCameraUploadStatus() async throws {
        
        guard featureFlagProvider.isFeatureFlagEnabled(for: .timelineCameraUploadStatus) else {
            return
        }
        
        for await status in monitorCameraUploadBannerStatusProvider.monitorCameraUploadStatusSequence() {
            try Task.checkCancellation()
            cameraUploadBannerStatusViewState = status
        }
    }
    
    @MainActor
    func handleCameraUploadAutoDismissal() async throws {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .timelineCameraUploadStatus) else {
            return
        }
        
        let asyncPublisher = $cameraUploadStatusShown
            .map { [weak self] isBannerShown -> AnyPublisher<Void, Never> in
                guard let self, isBannerShown else {
                    return Empty().eraseToAnyPublisher()
                }
                return $cameraUploadBannerStatusViewState
                    .removeDuplicates(by: { previous, newValue in
                        // Ensure auto dismissal timer restarts on status changes that differ
                        switch (previous, newValue) {
                        case
                            (.uploadCompleted, .uploadCompleted),
                            (.uploadInProgress, .uploadInProgress),
                            (.uploadPartialCompleted, .uploadPartialCompleted),
                            (.uploadPaused, .uploadPaused):
                            return true
                        default:
                            return false
                        }
                    })
                    .map { _ in () }
                    .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .values
        
        for await _ in asyncPublisher {
            try Task.checkCancellation()
            cameraUploadStatusShown = false
        }
    }
    
    func tappedCameraUploadBannerStatus() {
        cameraUploadStatusShown = false
        guard case .uploadPartialCompleted(reason: .photoLibraryLimitedAccess) = cameraUploadBannerStatusViewState else {
            return
        }
        
        showPhotoPermissionAlert = true
    }
    
    private func subscribeToHandleAutoPresentation() {
        $cameraUploadBannerStatusViewState
            .drop(while: { state in
                switch state {
                case .uploadInProgress, .uploadPaused:
                    return false
                case .uploadPartialCompleted, .uploadCompleted:
                    return true
                }
            })
            .filter { state -> Bool in
                switch state {
                case .uploadInProgress:
                    return false
                case .uploadPaused, .uploadPartialCompleted, .uploadCompleted:
                    return true
                }
            }
            .map { _ in true }
            .receive(on: DispatchQueue.main)
            .assign(to: &$cameraUploadStatusShown)
    }
}
