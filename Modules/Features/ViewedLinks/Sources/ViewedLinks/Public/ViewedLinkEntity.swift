import Foundation
import MEGADomain

/// A file or folder public link the user has opened, identified by its node handle.
public struct ViewedLinkEntity: Sendable {
    public let handle: HandleEntity
    public let linkURL: URL
    public let name: String
    public let isFolder: Bool
    public let lastAccessed: Date

    public init(
        handle: HandleEntity,
        linkURL: URL,
        name: String,
        isFolder: Bool,
        lastAccessed: Date
    ) {
        self.handle = handle
        self.linkURL = linkURL
        self.name = name
        self.isFolder = isFolder
        self.lastAccessed = lastAccessed
    }
}
