public struct MediaDestinationRepositoryDTO: Sendable, Equatable {
    public let fingerprint: String?
    public let destination: Int
    public let timescale: Int?
    
    public init(
        fingerprint: String?,
        destination: Int,
        timescale: Int?
    ) {
        self.fingerprint = fingerprint
        self.destination = destination
        self.timescale = timescale
    }
}
