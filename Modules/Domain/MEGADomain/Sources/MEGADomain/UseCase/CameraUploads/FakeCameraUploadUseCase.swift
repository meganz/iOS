import MEGASwift

/// Simulate uploading of photos till completion. This is for testing purposes only until actual upload use case is implemented.
public struct FakeCameraUploadSuccessfulUseCase: MonitorCameraUploadUseCaseProtocol {
    private let _monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity>
    
    public init(photoUploadCount: UInt = 100,
                pendingVideosCount: UInt = 0,
                initialDelayInNanoSeconds: UInt64 = 1_000_000_000,
                delayBetweenItemsInNanoSeconds: UInt64 = 100_000_000) {
        _monitorUploadStats = UploadPhotosAsyncSequence(
            uploadCount: photoUploadCount,
            pendingVideosCount: pendingVideosCount,
            initialDelayInNanoSeconds: initialDelayInNanoSeconds,
            delayBetweenItemsInNanoSeconds: delayBetweenItemsInNanoSeconds
        ).eraseToAnyAsyncSequence()
    }
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        _monitorUploadStats
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        .notPaused
    }
    
    private struct UploadPhotosAsyncSequence: AsyncSequence {
        typealias Element = CameraUploadStatsEntity
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
            typealias Element = CameraUploadStatsEntity
            
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
            
            mutating func next() async -> CameraUploadStatsEntity? {
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
                return nextValue
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
    
    public let _monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity>
    
    public init() {
        _monitorUploadStats = SingleItemAsyncSequence(
            item: .init(
                progress: 0.5,
                pendingFilesCount: 12,
                pendingVideosCount: 0))
        .eraseToAnyAsyncSequence()
    }
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        _monitorUploadStats
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        .notPaused
    }
}

/// Simulate no items to upload. This is for testing purposes only until actual upload use case is implemented.
public struct FakeNoItemsToUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    public let _monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity> = EmptyAsyncSequence<CameraUploadStatsEntity>().eraseToAnyAsyncSequence()
    
    public init() {}
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        _monitorUploadStats
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        .notPaused
    }
}
