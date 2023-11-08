import MEGASwift

/// Simulate uploading of photos till completion. This is for testing purposes only until actual upload use case is implemented.
public struct FakeCameraUploadSuccessfulUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>>
    
    public init(photoUploadCount: UInt = 10_000,
                initialDelayInNanoSeconds: UInt64 = 1_000_000_000) {
        monitorUploadStatus = UploadPhotosAsyncSequence(
            uploadCount: photoUploadCount,
            initialDelayInNanoSeconds: initialDelayInNanoSeconds
        ).eraseToAnyAsyncSequence()
    }
    
    private struct UploadPhotosAsyncSequence: AsyncSequence {
        typealias Element = Result<CameraUploadStatsEntity, Error>
        private let uploadCount: UInt
        private let initialDelayInNanoSeconds: UInt64
        
        init(uploadCount: UInt,
             initialDelayInNanoSeconds: UInt64) {
            self.uploadCount = uploadCount
            self.initialDelayInNanoSeconds = initialDelayInNanoSeconds
        }
        
        struct UploadPhotosAsyncIterator: AsyncIteratorProtocol {
            typealias Element = Result<CameraUploadStatsEntity, Error>
            
            private let uploadCount: UInt
            private let initialDelayInNanoSeconds: UInt64
            private var currentCount: UInt = 0
            
            init(uploadCount: UInt, initialDelayInNanoSeconds: UInt64) {
                self.uploadCount = uploadCount
                self.initialDelayInNanoSeconds = initialDelayInNanoSeconds
            }
            
            mutating func next() async -> Result<CameraUploadStatsEntity, Error>? {
                guard !Task.isCancelled,
                      currentCount <= uploadCount else {
                    return nil
                }
                if currentCount == 0 {
                    try? await Task.sleep(nanoseconds: initialDelayInNanoSeconds)
                }
                let nextValue = CameraUploadStatsEntity(
                    progress: Float(currentCount) / Float(uploadCount),
                    pendingFilesCount: uploadCount - currentCount)
                currentCount += 1
                return .success(nextValue)
            }
        }
        
        func makeAsyncIterator() -> UploadPhotosAsyncIterator {
            UploadPhotosAsyncIterator(uploadCount: uploadCount,
                                      initialDelayInNanoSeconds: initialDelayInNanoSeconds)
        }
    }
}

/// Simulate no items to upload. This is for testing purposes only until actual upload use case is implemented.
public struct FakeNoItemsToUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>> = EmptyAsyncSequence<Result<CameraUploadStatsEntity, Error>>().eraseToAnyAsyncSequence()
    
    public init() {}
}

/// Simulate upload failed. This is for testing purposes only until actual upload use case is implemented.
public struct FakeCameraUploadFailedUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>>
    
    public init() {
        monitorUploadStatus = SingleItemAsyncSequence(item: .failure(GenericErrorEntity())).eraseToAnyAsyncSequence()
    }
}
