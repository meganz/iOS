import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGASwift

final class CameraUploadStatusBannerViewModel: ObservableObject {
    
    @Published var cameraUploadStatusShown = false
    @Published private(set) var cameraUploadBannerStatusViewState: CameraUploadBannerStatusViewStates = .uploadCompleted
    @Published var showPhotoPermissionAlert = false
    
    private var monitorCameraUploadStatusProvider: MonitorCameraUploadStatusProvider
    private let cameraUploadsSettingsViewRouter: any Routing
    
    init(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        devicePermissionHandler: some DevicePermissionsHandling,
        cameraUploadsSettingsViewRouter: some Routing
    ) {
        self.monitorCameraUploadStatusProvider = MonitorCameraUploadStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler)
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        subscribeToHandleAutoPresentation()
    }
        
    @MainActor
    func monitorCameraUploadStatus() async throws {
        for await status in monitorCameraUploadStatusProvider.monitorCameraUploadBannerStatusSequence() {
            try Task.checkCancellation()
            cameraUploadBannerStatusViewState = status
        }
    }
    
    @MainActor
    func handleCameraUploadAutoDismissal() async throws {
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
        switch cameraUploadBannerStatusViewState {
        case .uploadPaused(reason: .noWifiConnection):
            cameraUploadsSettingsViewRouter.start()
        case .uploadPartialCompleted(reason: .photoLibraryLimitedAccess):
            showPhotoPermissionAlert = true
        default:
            break
        }
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
            .removeDuplicates()
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
