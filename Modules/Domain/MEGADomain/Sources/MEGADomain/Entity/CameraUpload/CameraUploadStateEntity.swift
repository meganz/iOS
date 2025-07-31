public enum CameraUploadStateEntity: Sendable, Equatable {
    case uploadStats(CameraUploadStatsEntity)
    case paused(reason: PausedReason)
    
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
