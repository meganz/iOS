import Foundation
import UniformTypeIdentifiers

public struct SpotlightSearchableItemEntity: Sendable, Equatable {
    public let uniqueIdentifier: String
    public let domainIdentifier: String
    public let contentType: UTType
    public let title: String
    public let contentDescription: String?
    public let thumbnailData: Data?
    
    public init(uniqueIdentifier: String, domainIdentifier: String, contentType: UTType, title: String, contentDescription: String?, thumbnailData: Data?) {
        self.uniqueIdentifier = uniqueIdentifier
        self.domainIdentifier = domainIdentifier
        self.contentType = contentType
        self.title = title
        self.contentDescription = contentDescription
        self.thumbnailData = thumbnailData
    }
}
