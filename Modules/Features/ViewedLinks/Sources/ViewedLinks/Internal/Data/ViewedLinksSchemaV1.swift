import Foundation
import SwiftData

typealias ViewedLinkModel = ViewedLinksSchemaV1.ViewedLinkModel

/// Frozen version-1 snapshot of the persisted schema. Nesting the model inside the versioned schema
/// keeps this definition stable so a later version can migrate from it.
enum ViewedLinksSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [ViewedLinkModel.self] }

    @Model
    final class ViewedLinkModel {
        /// The SDK's `UInt64` node handle, bit-reinterpreted to `Int64` so it stays a plain integer column.
        var handle: Int64
        var linkURL: String
        var name: String
        var isFolder: Bool
        /// Defaulted so an existing store migrates without a new schema version. A row written
        /// before this column existed reads back as `false` until the link is opened again.
        var hasThumbnail: Bool = false
        var lastAccessed: Date

        init(handle: Int64, linkURL: String, name: String, isFolder: Bool, hasThumbnail: Bool, lastAccessed: Date) {
            self.handle = handle
            self.linkURL = linkURL
            self.name = name
            self.isFolder = isFolder
            self.hasThumbnail = hasThumbnail
            self.lastAccessed = lastAccessed
        }
    }
}
