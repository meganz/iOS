public protocol NodeCoordinatesRepositoryProtocol: RepositoryProtocol, Sendable {
    func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws
}
