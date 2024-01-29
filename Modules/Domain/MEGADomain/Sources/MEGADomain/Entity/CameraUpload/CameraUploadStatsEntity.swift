import Foundation

public struct CameraUploadStatsEntity: Sendable, Equatable {
    public let progress: Float
    public let pendingFilesCount: UInt
    public let pendingVideosCount: UInt
    
    public init(progress: Float, pendingFilesCount: UInt, pendingVideosCount: UInt) {
        self.progress = progress
        self.pendingFilesCount = pendingFilesCount
        self.pendingVideosCount = pendingVideosCount
    }
}
