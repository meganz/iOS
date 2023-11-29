import MEGASwift

/// Simulate uploading of photos till completion. This is for testing purposes only until actual upload use case is implemented.
public struct FakeCameraUploadSuccessfulUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>>
    
    public init(photoUploadCount: UInt = 100,
                pendingVideosCount: UInt = 0,
                initialDelayInNanoSeconds: UInt64 = 1_000_000_000,
                delayBetweenItemsInNanoSeconds: UInt64 = 100_000_000) {
        monitorUploadStatus = UploadPhotosAsyncSequence(
            uploadCount: photoUploadCount, 
            pendingVideosCount: pendingVideosCount,
            initialDelayInNanoSeconds: initialDelayInNanoSeconds,
            delayBetweenItemsInNanoSeconds: delayBetweenItemsInNanoSeconds
        ).eraseToAnyAsyncSequence()
    }
    
    private struct UploadPhotosAsyncSequence: AsyncSequence {
        typealias Element = Result<CameraUploadStatsEntity, Error>
        private let uploadCount: UInt
        private let pendingVideosCount: UInt
        private let initialDelayInNanoSeconds: UInt64
        private let delayBetweenItemsInNanoSeconds: UInt64
        
        init(uploadCount: UInt,
             pendingVideosCount: UInt,
             initialDelayInNanoSeconds: UInt64,
             delayBetweenItemsInNanoSeconds: UInt64) {
            self.uploadCount = uploadCount
            self.pendingVideosCount = pendingVideosCount
            self.initialDelayInNanoSeconds = initialDelayInNanoSeconds
            self.delayBetweenItemsInNanoSeconds = delayBetweenItemsInNanoSeconds
        }
        
        struct UploadPhotosAsyncIterator: AsyncIteratorProtocol {
            typealias Element = Result<CameraUploadStatsEntity, Error>
            
            private let uploadCount: UInt
            private let pendingVideosCount: UInt
            private let initialDelayInNanoSeconds: UInt64
            private let delayBetweenItemsInNanoSeconds: UInt64
            private var currentCount: UInt = 0
            
            init(uploadCount: UInt,
                 pendingVideosCount: UInt,
                 initialDelayInNanoSeconds: UInt64,
                 delayBetweenItemsInNanoSeconds: UInt64) {
                self.uploadCount = uploadCount
                self.pendingVideosCount = pendingVideosCount
                self.initialDelayInNanoSeconds = initialDelayInNanoSeconds
                self.delayBetweenItemsInNanoSeconds = delayBetweenItemsInNanoSeconds
            }
            
            mutating func next() async -> Result<CameraUploadStatsEntity, Error>? {
                guard !Task.isCancelled,
                      currentCount <= uploadCount else {
                    return nil
                }
                try? await Task.sleep(nanoseconds: currentCount == 0 ? initialDelayInNanoSeconds : delayBetweenItemsInNanoSeconds)
                guard !Task.isCancelled else { return nil }
                
                let nextValue = CameraUploadStatsEntity(
                    progress: Float(currentCount) / Float(uploadCount),
                    pendingFilesCount: uploadCount - currentCount, 
                    pendingVideosCount: pendingVideosCount)
                currentCount += 1
                return .success(nextValue)
            }
        }
        
        func makeAsyncIterator() -> UploadPhotosAsyncIterator {
            UploadPhotosAsyncIterator(uploadCount: uploadCount, 
                                      pendingVideosCount: pendingVideosCount,
                                      initialDelayInNanoSeconds: initialDelayInNanoSeconds,
                                      delayBetweenItemsInNanoSeconds: delayBetweenItemsInNanoSeconds)
        }
    }
}

/// Simulate upload paused. This is for testing purposes only until actual upload use case is implemented.
public struct FakeCameraUploadPausedUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>>
    
    public init() {
        monitorUploadStatus = SingleItemAsyncSequence(
            item: .success(.init(
                progress: 0.5, pendingFilesCount: 12, pendingVideosCount: 0))).eraseToAnyAsyncSequence()
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
