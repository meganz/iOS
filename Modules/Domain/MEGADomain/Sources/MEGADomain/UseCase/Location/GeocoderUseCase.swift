import Foundation

public protocol GeoCoderUseCaseProtocol: Sendable {
    /// Perform reverse lookup of the provided geolocation coordinated, to generate a NodePlaceMarkEntity that describes the location and its area in human readable meta information.
    ///  e.g town, city, country and interesting points in the location.
    /// - Parameters:
    ///   - latitude: Double representation of latitude for a given coordinate
    ///   - longitude: Double representation of longitude for a given coordinate
    /// - Returns: NodePlaceMarkEntity for the given location, or throws an error if can't perform the request.
    func placeMark(for node: NodeEntity) async throws -> PlaceMarkEntity
}

public struct GeoCoderUseCase<T: GeoCoderRepositoryProtocol>: GeoCoderUseCaseProtocol {
    
    private let geoCoderRepository: T
    
    public init(geoCoderRepository: T) {
        self.geoCoderRepository = geoCoderRepository
    }
    
    public func placeMark(for node: NodeEntity) async throws -> PlaceMarkEntity {
        guard
            let latitude = node.latitude,
            let longitude = node.longitude else {
            throw GeoCoderErrorEntity.noCoordinatesProvided
        }
        
        return try await geoCoderRepository.placeMark(latitude: latitude, longitude: longitude)
    }
}
