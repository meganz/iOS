import Foundation

public struct CameraUploadStatsEntity {
    public let progress: Float
    public let pendingFilesCount: UInt
    
    public init(progress: Float, pendingFilesCount: UInt) {
        self.progress = progress
        self.pendingFilesCount = pendingFilesCount
    }
}
