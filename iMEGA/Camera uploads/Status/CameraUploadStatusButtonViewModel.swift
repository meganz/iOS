import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGAPreference
import SwiftUI

@MainActor
final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    @Published private(set) var monitorTaskId = UUID()
    
    let imageViewModel: CameraUploadStatusImageViewModel
    
    private let idleWaitTimeNanoSeconds: UInt64
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private var delayedStatusChangeTask: Task<Void, any Error>?
    
    private let monitorCameraUploadStatusProvider: MonitorCameraUploadStatusProvider
    private let cameraUploadsSettingsViewRouter: any Routing
    private let cameraUploadProgressRouter: any CameraUploadProgressRouting
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let tracker: any AnalyticsTracking
    
    var onTappedHandler: (() -> Void)?
    
    init(
        idleWaitTimeNanoSeconds: UInt64 = 3 * 1_000_000_000,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        devicePermissionHandler: some DevicePermissionsHandling,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        cameraUploadsSettingsViewRouter: some Routing,
        cameraUploadProgressRouter: some CameraUploadProgressRouting,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        featureFlagProvider: any FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.idleWaitTimeNanoSeconds = idleWaitTimeNanoSeconds
        self.monitorCameraUploadStatusProvider = MonitorCameraUploadStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            featureFlagProvider: featureFlagProvider)
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.cameraUploadProgressRouter = cameraUploadProgressRouter
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.tracker = tracker
        imageViewModel = CameraUploadStatusImageViewModel(
            status: preferenceUseCase[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] ?? false ? .checkPendingItemsToUpload : .turnedOff)
        super.init()
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
        
    func monitorCameraUpload() async {

        guard isCameraUploadsEnabled else {
            updateStatus(.turnedOff)
            return
        }
        
        updateStatus(.checkPendingItemsToUpload)
        
        var hasFinishedDroppingResult = false
        for await status in monitorCameraUploadStatusProvider.monitorCameraUploadImageStatusSequence() {
            // If first result is completed, we want to delay it to go straight to idle completed state.
            // And not show the green tick, as nothing has uploaded since loading this view
            if !hasFinishedDroppingResult, status == .completed {
                uploadCompleteIdleCheck()
                continue
            } else if !hasFinishedDroppingResult {
                hasFinishedDroppingResult = true
            }
            cancelDelayedStatusChangeTask()
            handleStatusUpdate(status)
        }
    }
    
    func onViewDisappear() {
        cancelDelayedStatusChangeTask()
    }
    
    func onTapped() {
        if remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMediaRevamp) {
            tracker.trackAnalyticsEvent(with: MediaScreenTransfersMenuToolbarEvent())
            guard isCameraUploadsEnabled else {
                cameraUploadsSettingsViewRouter.start()
                return
            }
            cameraUploadProgressRouter.start { [weak self] in
                self?.restartMonitoring()
            }
        } else {
            onTappedHandler?()
        }
    }
    
    func restartMonitoring() {
        monitorTaskId = UUID()
    }
    
    // MARK: - Private Functions
    
    private func handleStatusUpdate(_ status: CameraUploadStatus) {
        if status == .completed {
            uploadCompleteIdleCheck()
        }
        updateStatus(status)
    }
    
    private func updateStatus(_ status: CameraUploadStatus) {
        imageViewModel.status = status
    }
    
    // After the upload is complete the green checkmark should turn dark grey after a few seconds.
    private func uploadCompleteIdleCheck() {
        cancelDelayedStatusChangeTask()
        delayedStatusChangeTask = Task {
            try await Task.sleep(nanoseconds: idleWaitTimeNanoSeconds)
            updateStatus(monitorCameraUploadStatusProvider.hasLimitedLibraryAccess() ? .warning : .idle)
            cancelDelayedStatusChangeTask()
        }
    }
    
    private func cancelDelayedStatusChangeTask() {
        delayedStatusChangeTask?.cancel()
        delayedStatusChangeTask = nil
    }
}
