import FileProvider
import MEGAPickerFileProviderDomain
import MEGASwift
import UniformTypeIdentifiers

/// A node served by the replicated extension. Every attribute is taken from the node snapshot it was built from,
/// so reading one never goes back to the SDK.
final class ReplicatedFileProviderItem: NSObject, NSFileProviderItem {
    private let entity: FileProviderItemEntity

    init(entity: FileProviderItemEntity) {
        self.entity = entity
    }

    var itemIdentifier: NSFileProviderItemIdentifier {
        entity.identifier
    }

    var parentItemIdentifier: NSFileProviderItemIdentifier {
        entity.parentIdentifier
    }

    var filename: String {
        entity.node.name
    }

    var contentType: UTType {
        guard entity.node.isFile else {
            return .folder
        }
        return UTType(filenameExtension: entity.node.name.pathExtension) ?? .data
    }

    /// Read-only until the write operations are implemented: advertising more would let Files start changes the
    /// extension rejects.
    var capabilities: NSFileProviderItemCapabilities {
        entity.node.isFile ? [.allowsReading] : [.allowsReading, .allowsContentEnumerating]
    }

    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: entity.contentVersion, metadataVersion: entity.metadataVersion)
    }

    var childItemCount: NSNumber? {
        entity.childCount.map { NSNumber(value: $0) }
    }

    var documentSize: NSNumber? {
        entity.node.isFile ? NSNumber(value: entity.node.size) : nil
    }

    var creationDate: Date? {
        entity.node.creationTime
    }

    var contentModificationDate: Date? {
        entity.node.isFile ? entity.node.modificationTime : nil
    }
}
