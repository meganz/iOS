@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain

/// Enumerates the children of a container one page at a time, recording each page in the container's snapshot.
///
/// Changes reach the system through the working set (`ReplicatedWorkingSetEnumerator`), so this enumerator reports
/// none against a fixed anchor.
final class ReplicatedFileProviderEnumerator: NSObject, NSFileProviderEnumerator, Sendable {
    private static var syncAnchor: NSFileProviderSyncAnchor {
        NSFileProviderSyncAnchor(Data("0".utf8))
    }

    /// Used when the system does not suggest a page size. Each page builds all of its items at once, so this is
    /// kept small for the extension's memory limit.
    static let defaultPageSize = 200

    private let containerIdentifier: NSFileProviderItemIdentifier
    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let enumerationSnapshotUseCase: any FileProviderEnumerationSnapshotUseCaseProtocol

    init(
        containerIdentifier: NSFileProviderItemIdentifier,
        itemUseCase: some FileProviderItemUseCaseProtocol,
        enumerationSnapshotUseCase: some FileProviderEnumerationSnapshotUseCaseProtocol
    ) {
        self.containerIdentifier = containerIdentifier
        self.itemUseCase = itemUseCase
        self.enumerationSnapshotUseCase = enumerationSnapshotUseCase
    }

    func invalidate() {}

    func enumerateItems(for observer: any NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let offset = page.offset
        let pageSize = observer.suggestedPageSize.flatMap { $0 > 0 ? $0 : nil } ?? Self.defaultPageSize
        Task { [containerIdentifier, itemUseCase, enumerationSnapshotUseCase] in
            do {
                try await FileProviderSession.shared.ensureReady()
                let items = try await itemUseCase.children(
                    of: containerIdentifier,
                    page: SearchPageEntity(startingOffset: offset, pageSize: pageSize)
                )
                // Recorded before the system has them: a snapshot may hold more than the system, never less.
                try await enumerationSnapshotUseCase.didEnumerate(items, in: containerIdentifier)
                observer.didEnumerate(items.map(ReplicatedFileProviderItem.init(entity:)))
                // A short page is the last one.
                observer.finishEnumerating(upTo: items.count < pageSize ? nil : NSFileProviderPage(offset: offset + items.count))
            } catch {
                MEGALogError("[Picker] Can't enumerate \(containerIdentifier.rawValue) from offset \(offset): \(error)")
                observer.finishEnumeratingWithError(FileProviderExtension.fileProviderError(for: error))
            }
        }
    }

    func enumerateChanges(for observer: any NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        observer.finishEnumeratingChanges(upTo: Self.syncAnchor, moreComing: false)
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(Self.syncAnchor)
    }
}
