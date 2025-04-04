import MEGAAppSDKRepo

extension MOMediaDestination {
    
    func toMediaDestinationRepositoryDTO() -> MediaDestinationRepositoryDTO {
        MediaDestinationRepositoryDTO(
            fingerprint: fingerprint ?? "",
            destination: Int(truncating: destination ?? 0),
            timescale: Int(truncating: timescale ?? 0)
        )
    }
}
