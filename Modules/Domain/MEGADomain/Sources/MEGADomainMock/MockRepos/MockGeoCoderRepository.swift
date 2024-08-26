import MEGADomain

public struct MockGeoCoderRepository: GeoCoderRepositoryProtocol {
    
    public static var newRepo: MockGeoCoderRepository {
        .init()
    }

    private let placeMark: Result<PlaceMarkEntity, Error>
    
    public init(placeMark: Result<PlaceMarkEntity, Error> = .failure(GeoCoderErrorEntity.noPlaceMarkFound)) {
        self.placeMark = placeMark
    }
    
    public func placeMark(latitude: Double, longitude: Double) async throws -> PlaceMarkEntity {
        try placeMark.get()
    }
}
