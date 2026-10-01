import Foundation
import SwiftData

typealias LeftOffItemModel = LeftOffItemsSchemaV1.LeftOffItemModel

/// Frozen version-1 snapshot of the persisted schema. Nesting the model inside the versioned schema
/// keeps this definition stable so a later version can migrate from it.
enum LeftOffItemsSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [LeftOffItemModel.self] }

    @Model
    final class LeftOffItemModel {
        /// The SDK's `UInt64` node handle, bit-reinterpreted to `Int64` so it stays a plain integer column.
        var handle: Int64
        var name: String
        var lastAccessed: Date

        init(handle: Int64, name: String, lastAccessed: Date) {
            self.handle = handle
            self.name = name
            self.lastAccessed = lastAccessed
        }
    }
}
