import Foundation

public struct FileLinkEntity: Sendable {
    public let linkURL: URL
    
    public init(linkURL: URL) {
        self.linkURL = linkURL
    }
}
