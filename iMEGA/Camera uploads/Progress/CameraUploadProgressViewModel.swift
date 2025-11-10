import MEGADomain
import MEGAL10n

@MainActor
final class CameraUploadProgressViewModel: ObservableObject {
    @Published private(set) var uploadStatus = ""
    @Published private(set) var cameraUploadProgressTableViewModel: CameraUploadProgressTableViewModel
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    
    init(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        queuedCameraUploadsUseCase: some QueuedCameraUploadsUseCaseProtocol
    ) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        cameraUploadProgressTableViewModel = .init(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            paginationManager: CameraUploadPaginationManager(
                pageSize: 30,
                lookAhead: 4,
                lookBehind: 4,
                queuedCameraUploadsUseCase: queuedCameraUploadsUseCase))
    }
    
    func monitorUploadStats() async {
        for await state in monitorCameraUploadUseCase.cameraUploadState {
            let pendingFilesCount = state.stats.pendingFilesCount
            let format = if state.pausedReason != nil {
                Strings.localized("cameraUploads.progress.paused.items", comment: "")
            } else {
                Strings.localized("cameraUploads.progress.uploading.items", comment: "")
            }
            uploadStatus = String(format: format, locale: .current, pendingFilesCount)
        }
    }
}
