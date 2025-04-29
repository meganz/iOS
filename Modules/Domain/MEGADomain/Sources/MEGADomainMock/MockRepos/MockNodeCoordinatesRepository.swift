import MEGADomain

public struct MockNodeCoordinatesRepository: NodeCoordinatesRepositoryProtocol {
    public static let newRepo: MockNodeCoordinatesRepository = MockNodeCoordinatesRepository()
    
    public func setUnshareableNodeCoordinates(_ node: NodeEntity, latitude: Double, longitude: Double) async throws { }
}
