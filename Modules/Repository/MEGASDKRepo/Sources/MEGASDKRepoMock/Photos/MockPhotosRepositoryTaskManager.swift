import MEGADomain
import MEGASDKRepo
import MEGASwift

public actor MockPhotosRepositoryTaskManager: PhotosRepositoryTaskManagerProtocol {
    public let photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]>
    
    public private(set) var startMonitoringCalled = 0
    public private(set) var stopMonitoringCalled = 0
    
    private let loadPhotosResult: Result<[NodeEntity], any Error>
    private var _didMonitoringTaskStop = true
    
    public init(didMonitoringTaskStop: Bool = true,
                loadPhotosResult: Result<[NodeEntity], any Error> = .failure(GenericErrorEntity()),
                photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence<[NodeEntity]>().eraseToAnyAsyncSequence()) {
        _didMonitoringTaskStop = didMonitoringTaskStop
        self.loadPhotosResult = loadPhotosResult
        self.photosUpdatedAsyncSequence = photosUpdatedAsyncSequence
    }
    
    public func loadAllPhotos(searchPhotosOperation: @escaping () async throws -> [NodeEntity]) async throws -> [NodeEntity] {
        try await withCheckedThrowingContinuation {
            $0.resume(with: loadPhotosResult)
        }
    }
    
    public func startBackgroundMonitoring() async {
        startMonitoringCalled += 1
        _didMonitoringTaskStop = false
    }
    
    public func stopBackgroundMonitoring() async {
        stopMonitoringCalled += 1
        _didMonitoringTaskStop = true
    }
    
    public func didMonitoringTaskStop() async -> Bool {
        _didMonitoringTaskStop
    }
}
