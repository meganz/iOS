public enum CameraAssetUploadStatusDTO: Sendable {
    case unknown
    case notStarted
    case notReady
    case queuedUp
    case processing
    case uploading
    case cancelled
    case failed
    case done
}
