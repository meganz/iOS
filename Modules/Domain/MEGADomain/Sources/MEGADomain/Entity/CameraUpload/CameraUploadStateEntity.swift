public struct CameraUploadStateEntity: Sendable, Equatable {
    public let stats: CameraUploadStatsEntity
    public let pausedReason: PausedReason?
    
    public init(
        stats: CameraUploadStatsEntity,
        pausedReason: PausedReason? = nil
    ) {
        self.stats = stats
        self.pausedReason = pausedReason
    }
    
    public enum PausedReason: Sendable, Equatable {
        case lowBattery
        case highThermalState
        case networkIssue(NetworkIssue)
        
        public enum NetworkIssue: Sendable, Equatable {
            case noConnection
            case noWifi
        }
    }
}
