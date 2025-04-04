public protocol AlbumCacheMonitorTaskManagerProtocol: Sendable {
    /// Start monitoring background updates that manages the album cache
    func startMonitoring() async
    /// Stop monitoring background updates that interact with album cache
    func stopMonitoring() async
    /// Check if any of the background monitoring tasks stopped
    /// - Returns: `true` if any of the background tasks stopped
    func didChildTaskStop() async -> Bool
}

public actor AlbumCacheMonitorTaskManager: AlbumCacheMonitorTaskManagerProtocol {
    enum ChildTaskIdentifier: CaseIterable {
        case cacheInvalidation
        case setUpdates
        case setElementUpdates
    }
    private let repositoryMonitor: any UserAlbumCacheRepositoryMonitorsProtocol
    private var monitorTasks: [ChildTaskIdentifier: Task<Void, Never>] = [:]
    
    public init(repositoryMonitor: some UserAlbumCacheRepositoryMonitorsProtocol) {
        self.repositoryMonitor = repositoryMonitor
    }
    
    deinit {
        monitorTasks.values.forEach { $0.cancel() }
    }
    
    public func startMonitoring() {
        startMonitorCacheInvalidationTriggers()
        startMonitoringSetUpdates()
        startMonitorSetElementUpdates()
    }
    
    public func stopMonitoring() {
        monitorTasks.values.forEach { $0.cancel() }
        monitorTasks.removeAll()
    }
    
    public func didChildTaskStop() -> Bool {
        monitorTasks.count != ChildTaskIdentifier.allCases.count
    }
    
    private func startMonitorCacheInvalidationTriggers() {
        startMonitoring(identifier: .cacheInvalidation) { [repositoryMonitor] in
            await repositoryMonitor.monitorCacheInvalidationTriggers()
        }
    }
    
    private func startMonitoringSetUpdates() {
        startMonitoring(identifier: .setUpdates) { [repositoryMonitor] in
            await repositoryMonitor.monitorSetUpdates()
        }
    }
    
    private func startMonitorSetElementUpdates() {
        startMonitoring(identifier: .setElementUpdates) { [repositoryMonitor] in
            await repositoryMonitor.monitorSetElementUpdates()
        }
    }
    
    private func startMonitoring(identifier: ChildTaskIdentifier,
                                 operation: @escaping @Sendable () async -> Void) {
        guard monitorTasks[identifier] == nil else {
            return
        }
        monitorTasks[identifier] = Task(priority: .background) { [weak self] in
            await operation()
            await self?.removeTask(for: identifier)
        }
    }
    
    private func removeTask(for identifier: ChildTaskIdentifier) {
        monitorTasks.removeValue(forKey: identifier)?.cancel()
    }
}
