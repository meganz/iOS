import Foundation

public protocol GeoCoderRepositoryProtocol: Sendable, RepositoryProtocol {
    
    /// Perform reverse lookup of the provided geolocation coordinated, to generate a NodePlaceMarkEntity that describes the location and its area in human readable meta information.
    ///  e.g town, city, country and interesting points in the location.
    /// - Parameters:
    ///   - latitude: Double representation of latitude for a given coordinate
    ///   - longitude: Double representation of longitude for a given coordinate
    /// - Returns: NodePlaceMarkEntity for the given location, or throws an error if can't perform the request.
    ///  some possible errors are a rate limit set by apple when perform geocoding requests.
    func placeMark(latitude: Double, longitude: Double) async throws -> PlaceMarkEntity
}
