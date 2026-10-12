@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGAPickerFileProviderDomain

/// Enumerates the working set: the children of every folder the system has enumerated, and the changes queued for
/// them since a sync anchor.
final class ReplicatedWorkingSetEnumerator: NSObject, NSFileProviderEnumerator, Sendable {
    private let workingSetItemsUseCase: any FileProviderWorkingSetItemsUseCaseProtocol
    private let changesUseCase: any FileProviderChangesUseCaseProtocol

    init(
        workingSetItemsUseCase: some FileProviderWorkingSetItemsUseCaseProtocol,
        changesUseCase: some FileProviderChangesUseCaseProtocol
    ) {
        self.workingSetItemsUseCase = workingSetItemsUseCase
        self.changesUseCase = changesUseCase
    }

    func invalidate() {}

    func enumerateItems(for observer: any NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        let pageSize = observer.suggestedPageSize.flatMap { $0 > 0 ? $0 : nil } ?? ReplicatedFileProviderEnumerator.defaultPageSize
        Task { [workingSetItemsUseCase] in
            do {
                try await FileProviderSession.shared.ensureReady()
                let workingSetPage = try await workingSetItemsUseCase.items(startingAt: page, pageSize: pageSize)
                observer.didEnumerate(workingSetPage.items.map(ReplicatedFileProviderItem.init(entity:)))
                observer.finishEnumerating(upTo: workingSetPage.nextPage)
            } catch {
                MEGALogError("[Picker] Can't enumerate the working set: \(error)")
                observer.finishEnumeratingWithError(FileProviderExtension.fileProviderError(for: error))
            }
        }
    }

    func enumerateChanges(for observer: any NSFileProviderChangeObserver, from anchor: NSFileProviderSyncAnchor) {
        let limit = observer.suggestedBatchSize.flatMap { $0 > 0 ? $0 : nil } ?? ReplicatedFileProviderEnumerator.defaultPageSize
        Task { [changesUseCase] in
            do {
                try await FileProviderSession.shared.ensureReady()
                let changeSet = try await changesUseCase.changes(from: anchor, limit: limit)
                MEGALogDebug("[Picker] Working set changes: \(changeSet.updatedItems.count) updated, \(changeSet.deletedIdentifiers.count) deleted")
                if !changeSet.updatedItems.isEmpty {
                    observer.didUpdate(changeSet.updatedItems.map(ReplicatedFileProviderItem.init(entity:)))
                }
                if !changeSet.deletedIdentifiers.isEmpty {
                    observer.didDeleteItems(withIdentifiers: changeSet.deletedIdentifiers)
                }
                observer.finishEnumeratingChanges(upTo: changeSet.anchor, moreComing: changeSet.moreComing)
            } catch {
                MEGALogError("[Picker] Can't enumerate the working set changes: \(error)")
                observer.finishEnumeratingWithError(FileProviderExtension.fileProviderError(for: error))
            }
        }
    }

    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        let completion = UncheckedSendableCompletion(completionHandler)
        Task { [changesUseCase] in
            do {
                completion.handler(try await changesUseCase.currentAnchor())
            } catch {
                MEGALogError("[Picker] Can't read the working set's sync anchor: \(error)")
                completion.handler(nil)
            }
        }
    }
}
