import MEGADomain

public extension PlaceMarkEntity {
    
    init(
        areasOfInterest: [String]? = nil,
        subLocality: String? = nil,
        locality: String? = nil,
        country: String? = nil,
        isTesting: Bool = true) {
        
        self.init(
            areasOfInterest: areasOfInterest,
            subLocality: subLocality,
            locality: locality,
            country: country)
    }
}
