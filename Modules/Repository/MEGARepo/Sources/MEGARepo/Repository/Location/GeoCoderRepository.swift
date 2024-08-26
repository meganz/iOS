@preconcurrency import CoreLocation
import MEGADomain

public struct GeoCoderRepository: GeoCoderRepositoryProtocol {
    
    public static var newRepo: GeoCoderRepository {
        .init(geoCoder: CLGeocoder())
    }
    
    private let geoCoder: CLGeocoder

    public init(geoCoder: CLGeocoder) {
        self.geoCoder = geoCoder
    }
    
    public func placeMark(latitude: Double, longitude: Double) async throws -> PlaceMarkEntity {
        guard let placeMark = try await geoCoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)).first else {
            throw GeoCoderErrorEntity.noPlaceMarkFound
        }
        
        return placeMark.toPlaceMarkEntity()
    }
}
