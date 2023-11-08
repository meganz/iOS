import MEGADomain
import SwiftUI

final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    let imageViewModel: CameraUploadStatusImageViewModel
    
    private let idleWaitTimeNanoSeconds: UInt64
    @PreferenceWrapper(key: .isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    private var checkIdleTask: Task<Void, Never>?
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    
    init(idleWaitTimeNanoSeconds: UInt64 = 3 * 1_000_000_000,
         monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        self.idleWaitTimeNanoSeconds = idleWaitTimeNanoSeconds
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        imageViewModel = CameraUploadStatusImageViewModel(
            status: preferenceUseCase[.isCameraUploadsEnabled] ?? false ? .checkPendingItemsToUpload : .turnedOff)
        super.init()
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
    
    func monitorCameraUpload() async {
        guard isCameraUploadsEnabled else { return }
        uploadCompleteIdleCheck()

        for await uploadStatsResult in monitorCameraUploadUseCase.monitorUploadStatus {
            cancelUploadCompleteIdleTask()
            
            switch uploadStatsResult {
            case .success(let uploadStats):
                await handleStatsUpdate(uploadStats)
            case .failure:
                await updateStatus(.warning)
            }
        }
    }
    
    func onViewAppear() {
        let updatedStatus = isCameraUploadsEnabled ? CameraUploadStatus.checkPendingItemsToUpload : .turnedOff
        guard imageViewModel.status != updatedStatus else { return }
        imageViewModel.status = updatedStatus
    }
    
    func onViewDisappear() {
        cancelUploadCompleteIdleTask()
    }
    
    // MARK: - Private Functions
    
    @MainActor
    private func handleStatsUpdate(_ uploadStats: CameraUploadStatsEntity) {
        guard uploadStats.pendingFilesCount > 0 else {
            imageViewModel.status = .completed
            uploadCompleteIdleCheck()
            return
        }
        imageViewModel.status = .uploading(progress: uploadStats.progress)
    }
    
    @MainActor
    private func updateStatus(_ status: CameraUploadStatus) {
        imageViewModel.status = status
    }
    
    // After the upload is complete the green checkmark should turn dark grey after a few seconds.
    private func uploadCompleteIdleCheck() {
        cancelUploadCompleteIdleTask()
        checkIdleTask = Task {
            defer {
                cancelUploadCompleteIdleTask()
            }
            try? await Task.sleep(nanoseconds: idleWaitTimeNanoSeconds)
            guard !Task.isCancelled else { return }
            await updateStatus(.idle)
        }
    }
    
    private func cancelUploadCompleteIdleTask() {
        checkIdleTask?.cancel()
        checkIdleTask = nil
    }
}