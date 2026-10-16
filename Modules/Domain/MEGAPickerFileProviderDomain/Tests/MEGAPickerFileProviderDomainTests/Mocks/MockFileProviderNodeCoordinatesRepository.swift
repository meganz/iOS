import MEGADomain

/// Records the coordinates set on each node, by its base64 handle.
actor MockFileProviderNodeCoordinatesRepository: NodeCoordinatesRepositoryProtocol {
    struct Coordinates: Equatable {
        let node: String
        let latitude: Double
        let longitude: Double
    }

    static var newRepo: MockFileProviderNodeCoordinatesRepository { MockFileProviderNodeCoordinatesRepository() }

    private(set) var coordinates: [Coordinates] = []

    func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws {
        coordinates.append(Coordinates(node: node.base64Handle, latitude: latitude, longitude: longitude))
    }
}
