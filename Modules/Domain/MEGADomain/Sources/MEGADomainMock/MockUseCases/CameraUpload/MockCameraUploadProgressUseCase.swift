import MEGADomain
import MEGASwift

public struct MockCameraUploadProgressUseCase: CameraUploadProgressUseCaseProtocol {
    public var cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity>
    
    private let inProgressFilesResult: Result<[CameraUploadFileDetailsEntity], any Error>
    private let uploadProgress: CameraUploadProgressEntity?
    private let uploadProgressUpdates: AnyAsyncSequence<CameraUploadProgressEntity>
    
    public init(
        cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        inProgressFilesResult: Result<[CameraUploadFileDetailsEntity], any Error> = .failure(GenericErrorEntity()),
        uploadProgress: CameraUploadProgressEntity? = nil,
        uploadProgressUpdates: AnyAsyncSequence<CameraUploadProgressEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.cameraUploadPhaseEventUpdates = cameraUploadPhaseEventUpdates
        self.inProgressFilesResult =  inProgressFilesResult
        self.uploadProgress = uploadProgress
        self.uploadProgressUpdates = uploadProgressUpdates
    }
    
    public func inProgressFiles() async throws -> [CameraUploadFileDetailsEntity] {
        try inProgressFilesResult.get()
    }
    
    public func uploadProgress(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> CameraUploadProgressEntity {
        uploadProgress ?? CameraUploadProgressEntity(percentage: 0, totalBytes: 0, bytesPerSecond: 0)
    }
    
    public func uploadProgressUpdates(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> AnyAsyncSequence<CameraUploadProgressEntity> {
        uploadProgressUpdates
    }
}
