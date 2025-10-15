public struct CameraUploadPhaseEventEntity: Sendable, Equatable {
    public let assetIdentifier: CameraUploadLocalIdentifierEntity
    public let phase: Phase
    
    public init(
        assetIdentifier: CameraUploadLocalIdentifierEntity,
        phase: Phase
    ) {
        self.assetIdentifier = assetIdentifier
        self.phase = phase
    }
    
    public enum Phase: Sendable, Equatable {
        case registered
        case uploading
        case completed
    }
}
