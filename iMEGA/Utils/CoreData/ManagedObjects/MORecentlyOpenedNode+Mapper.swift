import MEGADomain
import MEGASDKRepo

extension MORecentlyOpenedNode {
    
    func toRecentlyOpenedNodeRepositoryDTO() -> RecentlyOpenedNodeRepositoryDTO {
        RecentlyOpenedNodeRepositoryDTO(
            fingerprint: fingerprint,
            lastWatchedDate: lastOpenedDate,
            mediaDestination: mediaDestinationDTO()
        )
    }
    
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
    
    func toRecentlyOpenedNodeRepositoryDTOs() -> [RecentlyOpenedNodeRepositoryDTO] {
        map { $0.toRecentlyOpenedNodeRepositoryDTO() }
    }
}
