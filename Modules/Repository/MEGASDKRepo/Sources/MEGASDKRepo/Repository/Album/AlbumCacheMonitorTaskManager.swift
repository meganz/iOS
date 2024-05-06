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
        monitorTasks.keys.forEach {
            monitorTasks[$0]?.cancel()
            monitorTasks[$0] = nil
        }
    }
    
    public func didChildTaskStop() -> Bool {
        monitorTasks.count != ChildTaskIdentifier.allCases.count
    }
    
    private func startMonitorCacheInvalidationTriggers() {
        startMonitoring(identifier: .cacheInvalidation) { [weak self] in
            guard let self else { return }
            await repositoryMonitor.monitorCacheInvalidationTriggers()
        }
    }
    
    private func startMonitoringSetUpdates() {
        startMonitoring(identifier: .setUpdates) { [weak self] in
            guard let self else { return }
            await repositoryMonitor.monitorSetUpdates()
        }
    }
    
    private func startMonitorSetElementUpdates() {
        startMonitoring(identifier: .setElementUpdates) { [weak self] in
            guard let self else { return }
            await repositoryMonitor.monitorSetElementUpdates()
        }
    }
    
    private func startMonitoring(identifier: ChildTaskIdentifier,
                                 operation: @escaping () async -> Void) {
        guard monitorTasks[identifier] == nil else {
            return
        }
        monitorTasks[identifier] = Task(priority: .background) {
            await operation()
            monitorTasks[identifier] = nil
        }
    }
}
