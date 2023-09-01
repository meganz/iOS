import Foundation

public struct BannerEntity {
    public let identifier: Int
    public let title: String
    public let description: String
    public let backgroundImageURL: URL
    public let imageURL: URL
    public let url: URL?
    
    public init(identifier: Int,
                title: String,
                description: String,
                backgroundImageURL: URL,
                imageURL: URL,
                url: URL? = nil) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.backgroundImageURL = backgroundImageURL
        self.imageURL = imageURL
        self.url = url
    }
}
