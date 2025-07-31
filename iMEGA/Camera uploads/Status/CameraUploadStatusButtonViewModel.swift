import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGAPreference
import SwiftUI

@MainActor
final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    let imageViewModel: CameraUploadStatusImageViewModel
    
    private let idleWaitTimeNanoSeconds: UInt64
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private var delayedStatusChangeTask: Task<Void, any Error>?
    
    private let monitorCameraUploadStatusProvider: MonitorCameraUploadStatusProvider

    var onTappedHandler: (() -> Void)?
    
    init(
        idleWaitTimeNanoSeconds: UInt64 = 3 * 1_000_000_000,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        devicePermissionHandler: some DevicePermissionsHandling,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.idleWaitTimeNanoSeconds = idleWaitTimeNanoSeconds
        self.monitorCameraUploadStatusProvider = MonitorCameraUploadStatusProvider( 
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            featureFlagProvider: featureFlagProvider)
        
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
    
    func onTapped() { onTappedHandler?() }
    
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
