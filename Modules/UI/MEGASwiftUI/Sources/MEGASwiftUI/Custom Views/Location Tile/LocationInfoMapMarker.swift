import CoreLocation

public struct LocationInfoMapMarker<ID: Hashable>: Identifiable, Equatable {
    
    public let id: ID
    public let location: CLLocation
    public let locationTitle: String
    public let locationDescription: String
    
    public init(id: ID, location: CLLocation, locationTitle: String, locationDescription: String) {
        self.id = id
        self.location = location
        self.locationTitle = locationTitle
        self.locationDescription = locationDescription
    }
}
