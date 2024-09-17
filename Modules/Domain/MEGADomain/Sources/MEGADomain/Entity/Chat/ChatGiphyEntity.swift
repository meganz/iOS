public struct ChatGiphyEntity: Sendable {
    public let mp4Src: String?
    public let webpSrc: String?
    public let mp4Size: Int
    public let webpSize: Int
    public let title: String?
    public let width: Int32
    public let height: Int32
    
    public init(mp4Src: String?, webpSrc: String?, mp4Size: Int, webpSize: Int, title: String?, width: Int32, height: Int32) {
        self.mp4Src = mp4Src
        self.webpSrc = webpSrc
        self.mp4Size = mp4Size
        self.webpSize = webpSize
        self.title = title
        self.width = width
        self.height = height
    }
}
