public struct ChatGeolocationEntity: Sendable {
    public let longitude: Float
    public let latitude: Float
    public let image: String?
    
    public init(longitude: Float, latitude: Float, image: String?) {
        self.longitude = longitude
        self.latitude = latitude
        self.image = image
    }
}
