public struct ChatContainsMetaEntity: Sendable {
    public enum MetaType: Sendable {
        case invalid
        case richPreview
        case geolocation
        case giphy
    }
    
    public let type: MetaType?
    public let textMessage: String?
    public let richPreview: ChatRichPreviewEntity?
    public let geoLocation: ChatGeolocationEntity?
    public let giphy: ChatGiphyEntity?
    
    public init(type: MetaType?, textMessage: String?, richPreview: ChatRichPreviewEntity?, geoLocation: ChatGeolocationEntity?, giphy: ChatGiphyEntity?) {
        self.type = type
        self.textMessage = textMessage
        self.richPreview = richPreview
        self.geoLocation = geoLocation
        self.giphy = giphy
    }
}
