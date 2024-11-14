public typealias PSAIdentifier = Int64

public struct PSAEntity: Sendable {
    public let identifier: PSAIdentifier
    public let title: String?
    public let description: String?
    public let imageURL: String?
    public let positiveText: String?
    public let positiveLink: String?
    public let URLString: String?
    
    public init(identifier: PSAIdentifier, title: String?, description: String?, imageURL: String?, positiveText: String?, positiveLink: String?, URLString: String?) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.positiveText = positiveText
        self.positiveLink = positiveLink
        self.URLString = URLString
    }
}

extension PSAEntity: Equatable {
    public static func == (lhs: PSAEntity, rhs: PSAEntity) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
