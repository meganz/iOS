import MEGADomain

extension CameraUploadMediaTypePausedReason {
    public func toCameraUploadPausedReasonEntity() -> CameraUploadMediaTypePausedReasonEntity {
        switch self {
        case .lowBattery: .lowBattery
        case .thermalState(.critical): .thermalState(.critical)
        case .thermalState(.serious): .thermalState(.serious)
        }
    }
}
