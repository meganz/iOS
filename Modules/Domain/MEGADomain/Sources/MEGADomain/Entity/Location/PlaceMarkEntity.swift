public struct PlaceMarkEntity: Sendable, Equatable {
    /// eg. Golden Gate Park
    public let areasOfInterest: [String]?
    /// neighborhood, common name, eg. Mission District
    public let subLocality: String?
    /// city, eg. Cupertino
    public let locality: String?
    /// eg. United States
    public let country: String?
    
    public init(areasOfInterest: [String]?, subLocality: String?, locality: String?, country: String?) {
        self.areasOfInterest = areasOfInterest
        self.subLocality = subLocality
        self.locality = locality
        self.country = country
    }
}
