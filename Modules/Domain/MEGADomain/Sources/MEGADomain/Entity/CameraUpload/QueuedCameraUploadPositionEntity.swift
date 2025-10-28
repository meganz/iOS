import Foundation

public struct QueuedCameraUploadCursorEntity: Sendable, Equatable {
    public let localIdentifier: String
    public let creationDate: Date
    
    public init(localIdentifier: String, creationDate: Date) {
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
    }
}
