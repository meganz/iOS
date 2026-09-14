import Foundation
import SwiftData

/// Persisted Viewed Links record
@Model
final class ViewedLinkModel {
    /// The SDK's `UInt64` node handle, bit-reinterpreted to `Int64` so it stays a plain integer column.
    var handle: Int64
    var linkURL: String
    var name: String
    var isFolder: Bool
    var lastAccessed: Date

    init(handle: Int64, linkURL: String, name: String, isFolder: Bool, lastAccessed: Date) {
        self.handle = handle
        self.linkURL = linkURL
        self.name = name
        self.isFolder = isFolder
        self.lastAccessed = lastAccessed
    }
}

enum ViewedLinksSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ViewedLinkModel.self] }
}
