import MEGADomain

public struct MockGeoCoderUseCase: GeoCoderUseCaseProtocol {
    
    private let placeMark: Result<PlaceMarkEntity, any Error>
    
    public init(placeMark: Result<PlaceMarkEntity, any Error> = .failure(GeoCoderErrorEntity.noCoordinatesProvided)) {
        self.placeMark = placeMark
    }
    
    public func placeMark(for node: NodeEntity) async throws -> PlaceMarkEntity {
        try placeMark.get()
    }
}
