import Foundation

public struct CameraUploadTaskProgressRawDataEntity: Sendable {
    public struct SpeedSample: Sendable {
        public let timestamp: Date
        public let bytesSent: Int64
        
        public init(timestamp: Date, bytesSent: Int64) {
            self.timestamp = timestamp
            self.bytesSent = bytesSent
        }
    }

    public let totalBytesSent: Int64
    public let totalBytesExpected: Int64
    public let speedSamples: [SpeedSample]
    
    public init(
        totalBytesSent: Int64,
        totalBytesExpected: Int64,
        speedSamples: [SpeedSample]
    ) {
        self.totalBytesSent = totalBytesSent
        self.totalBytesExpected = totalBytesExpected
        self.speedSamples = speedSamples
    }
}
