import Foundation

public struct FileProviderItemMetadata: Codable {
    public var favoriteRank: Int64?
    public var tagData: Data?

    public init(favoriteRank: Int64? = nil, tagData: Data? = nil) {
        self.favoriteRank = favoriteRank
        self.tagData = tagData
    }
}
