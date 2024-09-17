public struct ChatRichPreviewEntity: Sendable {
    public let text: String?
    public let title: String?
    public let previewDescription: String?
    public let image: String?
    public let imageFormat: String?
    public let icon: String?
    public let iconFormat: String?
    public let url: String?
    
    public init(text: String?, title: String?, previewDescription: String?, image: String?, imageFormat: String?, icon: String?, iconFormat: String?, url: String?) {
        self.text = text
        self.title = title
        self.previewDescription = previewDescription
        self.image = image
        self.imageFormat = imageFormat
        self.icon = icon
        self.iconFormat = iconFormat
        self.url = url
    }
}
