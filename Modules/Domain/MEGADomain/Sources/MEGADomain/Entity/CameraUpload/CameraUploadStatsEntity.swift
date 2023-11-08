import Foundation

public struct CameraUploadStatsEntity: Sendable {
    public let progress: Float
    public let pendingFilesCount: UInt
    
    public init(progress: Float, pendingFilesCount: UInt) {
        self.progress = progress
        self.pendingFilesCount = pendingFilesCount
    }
}
