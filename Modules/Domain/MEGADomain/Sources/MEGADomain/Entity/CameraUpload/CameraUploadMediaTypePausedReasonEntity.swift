public enum CameraUploadMediaTypePausedReasonEntity: Sendable {
    case none
    case lowBattery
    case thermalState(ThermalState)
    
    public enum ThermalState: Sendable {
        case critical
        case serious
    }
}
