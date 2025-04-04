import MEGADomain

extension RecentlyOpenedNodeRepositoryDTO {
    
    func toRecentlyOpenedNodeEntity(node: NodeEntity) -> RecentlyOpenedNodeEntity {
        RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: lastOpenedDate,
            mediaDestination: mediaDestination.toMediaDestinationEntity()
        )
    }
}

extension MediaDestinationRepositoryDTO {
    
    func toMediaDestinationEntity() -> MediaDestinationEntity {
        MediaDestinationEntity(
            fingerprint: fingerprint,
            destination: destination,
            timescale: timescale
        )
    }
}
