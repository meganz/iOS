import MEGADomain
import MEGASwift

public struct MockCameraUploadTransferProgressRepository: CameraUploadTransferProgressRepositoryProtocol {
    public let activeUploads: [CameraUploadLocalIdentifierEntity]
    public let cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity>
    private let progressRawDataForIdentifier: [CameraUploadLocalIdentifierEntity: CameraUploadTaskProgressRawDataEntity]
    private let _progressRawDataUpdates: AnyAsyncSequence<CameraUploadTaskProgressRawDataEntity>
    
    public init(
        activeUploads: [CameraUploadLocalIdentifierEntity] = [],
        cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        progressRawDataForIdentifier: [CameraUploadLocalIdentifierEntity: CameraUploadTaskProgressRawDataEntity] = [:],
        progressRawDataUpdates: AnyAsyncSequence<CameraUploadTaskProgressRawDataEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.activeUploads = activeUploads
        self.cameraUploadPhaseEventUpdates = cameraUploadPhaseEventUpdates
        self.progressRawDataForIdentifier = progressRawDataForIdentifier
        _progressRawDataUpdates = progressRawDataUpdates
    }
    
    public func registerTask(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesExpectedToWrite: Int64) async {

    }
    
    public func updateTaskProgress(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesSent: Int64, totalBytesExpected: Int64) async {
        
    }
    
    public func completeTask(identifier: Int, info: CameraUploadTaskInfoEntity) async {
        
    }
    
    public func restoreTasks(for localIdentifier: CameraUploadLocalIdentifierEntity, taskIdentifierForChunk: [Int: Int], totalBytesSent: Int64, expectedBytesPerChunk: [Int: Int64]) async {
        
    }
    
    public func progressRawData(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> CameraUploadTaskProgressRawDataEntity {
        progressRawDataForIdentifier[localIdentifier] ?? .init(totalBytesSent: 0, totalBytesExpected: 0, speedSamples: [])
    }
    
    public func progressRawDataUpdates(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> AnyAsyncSequence<CameraUploadTaskProgressRawDataEntity> {
        _progressRawDataUpdates
    }
}
