import MEGAAppSDKRepo
import MEGADomain

extension MORecentlyOpenedNode {
    
    /// A mapping function from `MORecentlyOpenedNode` to `RecentlyOpenedNodeRepositoryDTO` type.
    /// - Returns: `RecentlyOpenedNodeRepositoryDTO` model representation
    /// - Important: Always access this function from CoreData context which deal with `MORecentlyOpenedNode`, otherwise CoreData will throw crash, to prevent potential CoreData corruption.
    func toRecentlyOpenedNodeRepositoryDTO() -> RecentlyOpenedNodeRepositoryDTO {
        RecentlyOpenedNodeRepositoryDTO(
            fingerprint: fingerprint,
            lastWatchedDate: lastOpenedDate,
            mediaDestination: mediaDestinationDTO()
        )
    }
    
    /// A mapping function from `MOMediaDestination` to `MediaDestinationRepositoryDTO` type.
    /// - Returns: `MediaDestinationRepositoryDTO` model representation
    /// - Important: Always access this function from CoreData context which deal with `MORecentlyOpenedNode`, otherwise CoreData will throw crash, to prevent potential CoreData corruption.
    private func mediaDestinationDTO() -> MediaDestinationRepositoryDTO {
        guard let destination = mediaDestination?.toMediaDestinationRepositoryDTO() else {
            return MediaDestinationRepositoryDTO(
                fingerprint: fingerprint ?? "",
                destination: Int(truncating: 0),
                timescale: Int(truncating: 0)
            )
        }
        return destination
    }
}

extension Array where Element == MORecentlyOpenedNode {
    
    /// A mapping function from `[MORecentlyOpenedNode]` to `[RecentlyOpenedNodeRepositoryDTO]` type.
    /// - Returns: `[RecentlyOpenedNodeRepositoryDTO]` model representation
    /// - Important: Always access this function from CoreData context which deal with `MORecentlyOpenedNode`, otherwise CoreData will throw crash, to prevent potential CoreData corruption.
    func toRecentlyOpenedNodeRepositoryDTOs() -> [RecentlyOpenedNodeRepositoryDTO] {
        map { $0.toRecentlyOpenedNodeRepositoryDTO() }
    }
}
