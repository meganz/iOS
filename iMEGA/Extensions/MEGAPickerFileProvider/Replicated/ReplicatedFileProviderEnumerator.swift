@preconcurrency import FileProvider

/// Enumerates nothing: the extension does not serve any node yet.
///
/// Changes are reported against a fixed anchor, so the system never finds a gap it would have to rescan for
/// until incremental changes are implemented.
final class ReplicatedFileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    private static var syncAnchor: NSFileProviderSyncAnchor {
        NSFileProviderSyncAnchor(Data("0".utf8))
    }

    func invalidate() {}

    func enumerateItems(for observer: any NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        observer.finishEnumerating(upTo: nil)
    }

    func enumerateChanges(for observer: any NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        observer.finishEnumeratingChanges(upTo: Self.syncAnchor, moreComing: false)
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(Self.syncAnchor)
    }
}
