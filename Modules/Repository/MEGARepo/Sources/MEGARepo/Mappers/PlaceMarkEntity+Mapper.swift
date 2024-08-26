import CoreLocation
import MEGADomain

extension CLPlacemark {
    func toPlaceMarkEntity() -> PlaceMarkEntity {
        .init(
            areasOfInterest: areasOfInterest,
            subLocality: subLocality,
            locality: locality,
            country: country)
    }
}
