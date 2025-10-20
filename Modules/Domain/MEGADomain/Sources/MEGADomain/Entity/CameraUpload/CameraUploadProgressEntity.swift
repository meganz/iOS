public struct CameraUploadProgressEntity: Sendable {
    public let percentage: Double
    public let totalBytes: Int64
    public let bytesPerSecond: Double
    
    public init(percentage: Double, totalBytes: Int64, bytesPerSecond: Double) {
        self.percentage = percentage
        self.totalBytes = totalBytes
        self.bytesPerSecond = bytesPerSecond
    }
}
