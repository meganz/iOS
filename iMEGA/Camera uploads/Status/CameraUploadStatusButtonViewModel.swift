import MEGADomain
import SwiftUI

final class CameraUploadStatusButtonViewModel: NSObject, ObservableObject {
    let imageViewModel = CameraUploadStatusImageViewModel(status: .turnedOff)
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        super.init()
    }
    
    func monitorCameraUpload() async {
        await updateStatus(.checkPendingItemsToUpload)
        for await uploadStats in monitorCameraUploadUseCase.monitorUploadStatus {
            guard uploadStats.pendingFilesCount > 0 else {
                await updateStatus(.completed)
                continue
            }
            await updateStatus(.uploading(progress: uploadStats.progress))
        }
    }
    
    @MainActor
    private func updateStatus(_ status: CameraUploadStatus) {
        imageViewModel.status = status
    }
}
