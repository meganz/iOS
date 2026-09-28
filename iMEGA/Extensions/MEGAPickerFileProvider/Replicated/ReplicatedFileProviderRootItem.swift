import FileProvider
import UniformTypeIdentifiers

/// The root of the MEGA domain. Files shows it under the domain's display name, not under `filename`.
final class ReplicatedFileProviderRootItem: NSObject, NSFileProviderItem {
    var itemIdentifier: NSFileProviderItemIdentifier {
        .rootContainer
    }

    var parentItemIdentifier: NSFileProviderItemIdentifier {
        .rootContainer
    }

    var filename: String {
        "MEGA"
    }

    var contentType: UTType {
        .folder
    }

    var capabilities: NSFileProviderItemCapabilities {
        [.allowsReading, .allowsContentEnumerating]
    }

    /// The root has no metadata of its own that can change, so its version never does either.
    var itemVersion: NSFileProviderItemVersion {
        NSFileProviderItemVersion(contentVersion: Data("root".utf8), metadataVersion: Data("root".utf8))
    }
}
