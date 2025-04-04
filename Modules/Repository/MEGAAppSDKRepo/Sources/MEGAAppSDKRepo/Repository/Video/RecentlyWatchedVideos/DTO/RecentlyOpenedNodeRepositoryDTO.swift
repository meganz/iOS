import Foundation

public struct RecentlyOpenedNodeRepositoryDTO: Sendable, Equatable {
    public let fingerprint: String?
    public let lastOpenedDate: Date?
    public let mediaDestination: MediaDestinationRepositoryDTO
    
    public init(
        fingerprint: String?,
        lastWatchedDate: Date?,
        mediaDestination: MediaDestinationRepositoryDTO
    ) {
        self.fingerprint = fingerprint
        self.lastOpenedDate = lastWatchedDate
        self.mediaDestination = mediaDestination
    }
}
