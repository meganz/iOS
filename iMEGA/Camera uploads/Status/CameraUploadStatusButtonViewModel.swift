import MEGADomain
import MEGAPermissions
import SwiftUI

final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    let imageViewModel: CameraUploadStatusImageViewModel
    
    private let idleWaitTimeNanoSeconds: UInt64
    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private var delayedStatusChangeTask: Task<Void, any Error>?
    
    private let monitorCameraUploadStatusProvider: MonitorCameraUploadStatusProvider

    var onTappedHandler: (() -> Void)?
    
    init(idleWaitTimeNanoSeconds: UInt64 = 3 * 1_000_000_000,
         monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.idleWaitTimeNanoSeconds = idleWaitTimeNanoSeconds
        self.monitorCameraUploadStatusProvider = MonitorCameraUploadStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler)
        
        imageViewModel = CameraUploadStatusImageViewModel(
            status: preferenceUseCase[.isCameraUploadsEnabled] ?? false ? .checkPendingItemsToUpload : .turnedOff)
        super.init()
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
        
    func monitorCameraUpload() async {

        guard isCameraUploadsEnabled else {
            await updateStatus(.turnedOff)
            return
        }
        
        await updateStatus(.checkPendingItemsToUpload)
        
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
            await handleStatusUpdate(status)
        }
    }
    
    func onViewDisappear() {
        cancelDelayedStatusChangeTask()
    }
    
    func onTapped() { onTappedHandler?() }
    
    // MARK: - Private Functions
    
    @MainActor
    private func handleStatusUpdate(_ status: CameraUploadStatus) {
        if status == .completed {
            uploadCompleteIdleCheck()
        }
        updateStatus(status)
    }
    
    @MainActor
    private func updateStatus(_ status: CameraUploadStatus) {
        imageViewModel.status = status
    }
    
    // After the upload is complete the green checkmark should turn dark grey after a few seconds.
    private func uploadCompleteIdleCheck() {
        cancelDelayedStatusChangeTask()
        delayedStatusChangeTask = Task {
            try await Task.sleep(nanoseconds: idleWaitTimeNanoSeconds)
            await updateStatus(monitorCameraUploadStatusProvider.hasLimitedLibraryAccess() ? .warning : .idle)
            cancelDelayedStatusChangeTask()
        }
    }
    
    private func cancelDelayedStatusChangeTask() {
        delayedStatusChangeTask?.cancel()
        delayedStatusChangeTask = nil
    }
}
