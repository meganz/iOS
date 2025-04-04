import MEGADomain
import MEGASwift

public protocol PhotosRepositoryTaskManagerProtocol: Sendable {
    /// Photo update async sequence that yields after background monitoring starts on node updates
    /// Returns: `AnyAsyncSequence` that will yield `[NodeEntity]` updated photos until sequence terminated or monitoring stopped
    var photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> { get async }
    /// Load all photos ensuring that any additional calls will reuse the ongoing task.
    /// It will store retrieved photos in local source (cache)
    func loadAllPhotos(searchPhotosOperation: @escaping @Sendable () async throws -> [NodeEntity]) async throws -> [NodeEntity]
    /// Start monitoring background updates that manages the album cache
    func startBackgroundMonitoring() async
    /// Stop monitoring background updates that interact with album cache
    func stopBackgroundMonitoring() async
    /// Check if any of the background monitoring tasks stopped
    /// - Returns: `true` if any of the background tasks stopped
    func didMonitoringTaskStop() async -> Bool
}

public actor PhotosRepositoryTaskManager: PhotosRepositoryTaskManagerProtocol {
    public var photosUpdatedAsyncSequence: AnyAsyncSequence<[NodeEntity]> {
        get async {
            await photoCacheRepositoryMonitors.photosUpdatedAsyncSequence
        }
    }
    
    enum MonitoringTaskIdentifier: CaseIterable {
        case cacheInvalidation
        case photoNodeUpdates
    }
    private let photoLocalSource: any PhotoLocalSourceProtocol
    private let photoCacheRepositoryMonitors: any PhotoCacheRepositoryMonitorsProtocol
    
    private var searchAllPhotosTask: Task<[NodeEntity], any Error>?
    private var monitorTasks: [MonitoringTaskIdentifier: Task<Void, Never>] = [:]
    
    public init(photoLocalSource: any PhotoLocalSourceProtocol,
                photoCacheRepositoryMonitors: any PhotoCacheRepositoryMonitorsProtocol) {
        self.photoLocalSource = photoLocalSource
        self.photoCacheRepositoryMonitors = photoCacheRepositoryMonitors
    }
    
    deinit {
        searchAllPhotosTask?.cancel()
        monitorTasks.values.forEach { $0.cancel() }
    }
    
    public func loadAllPhotos(
        searchPhotosOperation: @escaping @Sendable () async throws -> [NodeEntity]
    ) async throws -> [NodeEntity] {
        if let searchAllPhotosTask {
            return try await searchAllPhotosTask.value
        }
        let searchPhotosTask = Task<[NodeEntity], any Error> {
            return try await searchPhotosOperation()
        }
        self.searchAllPhotosTask = searchPhotosTask
        defer { self.searchAllPhotosTask = nil }
        
        return try await withTaskCancellationHandler { [weak photoLocalSource] in
            let photos = try await searchPhotosTask.value
            try Task.checkCancellation()
            await photoLocalSource?.setPhotos(photos)
            try Task.checkCancellation()
            return photos
        } onCancel: {
            searchPhotosTask.cancel()
        }
    }
    
    public func startBackgroundMonitoring() {
        startMonitorCacheInvalidationTriggers()
        startMonitoringPhotoNodeUpdates()
    }
    
    public func stopBackgroundMonitoring() {
        monitorTasks.values.forEach { $0.cancel() }
        monitorTasks.removeAll()
    }
    
    public func didMonitoringTaskStop() -> Bool {
        return monitorTasks.count != MonitoringTaskIdentifier.allCases.count
    }
    
    private func startMonitorCacheInvalidationTriggers() {
        startMonitoring(identifier: .cacheInvalidation) { [photoCacheRepositoryMonitors] in
            await photoCacheRepositoryMonitors.monitorCacheInvalidationTriggers()
        }
    }
    
    private func startMonitoringPhotoNodeUpdates() {
        startMonitoring(identifier: .photoNodeUpdates) { [photoCacheRepositoryMonitors] in
            await photoCacheRepositoryMonitors.monitorPhotoNodeUpdates()
        }
    }
    
    private func startMonitoring(identifier: MonitoringTaskIdentifier,
                                 operation: @escaping @Sendable () async -> Void) {
        guard monitorTasks[identifier] == nil else {
            return
        }
        monitorTasks[identifier] = Task(priority: .background) { [weak self] in
            await operation()
            await self?.removeTask(for: identifier)
        }
    }
    
    private func removeTask(for identifier: MonitoringTaskIdentifier) {
        monitorTasks.removeValue(forKey: identifier)?.cancel()
    }
}
