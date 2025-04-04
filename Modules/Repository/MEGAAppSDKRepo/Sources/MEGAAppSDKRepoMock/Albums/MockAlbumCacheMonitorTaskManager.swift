import MEGAAppSDKRepo

public actor MockAlbumCacheMonitorTaskManager: AlbumCacheMonitorTaskManagerProtocol {
    
    public private(set) var startMonitoringCalled = 0
    public private(set) var stopMonitoringCalled = 0
    private var _didChildTaskStop = true
    
    public init(didChildTaskStop: Bool = true) {
        _didChildTaskStop = didChildTaskStop
    }
    
    public func startMonitoring() {
        startMonitoringCalled += 1
        _didChildTaskStop = false
    }
    
    public func stopMonitoring() {
        stopMonitoringCalled += 1
        _didChildTaskStop = true
    }
    
    public func didChildTaskStop() -> Bool {
        _didChildTaskStop
    }
}
