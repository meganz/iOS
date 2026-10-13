@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGAPickerFileProviderRepo
import MEGARepo

/// Entry point of the File Provider extension on `NSFileProviderReplicatedExtension`.
///
/// Only used when the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting points at it; `FileProviderExtension`
/// stays the shipping implementation until the switch. For now it serves browsing and downloading, and keeps what
/// Files shows in step with remote changes.
final class ReplicatedFileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    /// Changes MEGA has nowhere to keep. The system sets the last used date whenever a file is opened, including
    /// when Files hands it over to another app.
    private static let unsupportedFields: NSFileProviderItemFields = [.lastUsedDate]

    private let domain: NSFileProviderDomain
    private let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)

    /// Built on every use rather than stored: its repositories reach `MEGASdk.shared`, which must not exist before
    /// `init` has copied the databases, and a `lazy var` is not safe to initialise from the concurrent calls the
    /// system makes.
    private var itemUseCase: some FileProviderItemUseCaseProtocol {
        FileProviderItemUseCase(
            filesSearchRepo: FilesSearchRepository.newRepo,
            nodeRepo: NodeRepository.newRepo,
            megaHandleRepo: MEGAHandleRepository.newRepo,
            nodeAttributeRepo: NodeAttributeRepository.newRepo
        )
    }

    /// Built on every use for the same reason as `itemUseCase`.
    private var contentUseCase: some FileProviderContentUseCaseProtocol {
        FileProviderContentUseCase(downloadRepo: FileProviderDownloadRepository.newRepo)
    }

    private var enumerationSnapshotUseCase: some FileProviderEnumerationSnapshotUseCaseProtocol {
        FileProviderEnumerationSnapshotUseCase(snapshotRepo: FileProviderSnapshotRepository.newRepo)
    }

    /// Built on every use for the same reason as `itemUseCase`.
    private var folderComparisonUseCase: some FileProviderFolderComparisonUseCaseProtocol {
        FileProviderFolderComparisonUseCase(
            itemUseCase: itemUseCase,
            snapshotRepo: FileProviderSnapshotRepository.newRepo,
            changeQueueRepo: FileProviderChangeQueueRepository.newRepo,
            workingSetSignalRepo: FileProviderWorkingSetSignalRepository.newRepo
        )
    }

    /// Built on every use for the same reason as `itemUseCase`.
    private var nodeUpdatesUseCase: some FileProviderNodeUpdatesUseCaseProtocol {
        FileProviderNodeUpdatesUseCase(
            nodeRepo: NodeRepository.newRepo,
            snapshotRepo: FileProviderSnapshotRepository.newRepo,
            changeQueueRepo: FileProviderChangeQueueRepository.newRepo,
            workingSetSignalRepo: FileProviderWorkingSetSignalRepository.newRepo
        )
    }

    /// Built on every use for the same reason as `itemUseCase`.
    private var workingSetEnumerator: ReplicatedWorkingSetEnumerator {
        ReplicatedWorkingSetEnumerator(
            workingSetItemsUseCase: FileProviderWorkingSetItemsUseCase(
                itemUseCase: itemUseCase,
                snapshotRepo: FileProviderSnapshotRepository.newRepo,
                enumerationSnapshotUseCase: enumerationSnapshotUseCase
            ),
            changesUseCase: FileProviderChangesUseCase(
                itemUseCase: itemUseCase,
                snapshotRepo: FileProviderSnapshotRepository.newRepo,
                changeQueueRepo: FileProviderChangeQueueRepository.newRepo
            )
        )
    }

    // Nothing here may create `MEGASdk.shared` before `copyDatabasesFromMainApp()`: an SDK that opens its
    // databases first stamps them with a fresh modification date, and the copy then wrongly skips them (IOS-7447).
    init(domain: NSFileProviderDomain) {
        FileProviderMemoryProbe.mark("init.begin")
        self.domain = domain
        super.init()
        AppEnvironmentConfigurator.configAppEnvironment()
#if DEBUG
        MEGASdk.setLogLevel(.max)
#endif
        MEGASdk.setLogToConsole(true)
        MEGALogDebug("[Picker] Replicated extension started for domain \(domain.identifier.rawValue)")
        copyDatabasesFromMainApp()
        FileProviderMemoryProbe.mark("init.end")
    }

    func invalidate() {
        MEGALogDebug("[Picker] Replicated extension invalidated for domain \(domain.identifier.rawValue)")
    }

    // MARK: - Items

    func item(
        for identifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        let itemUseCase = itemUseCase
        let completion = UncheckedSendableCompletion(completionHandler)
        Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                completion.handler(ReplicatedFileProviderItem(entity: try itemUseCase.item(for: identifier)), nil)
            } catch {
                MEGALogError("[Picker] Can't provide the item \(identifier.rawValue): \(error)")
                completion.handler(nil, FileProviderExtension.fileProviderError(for: error))
            }
        }
        return Progress()
    }

    /// `requestedVersion` is always `nil` (see `NSFileProviderReplicatedExtension.h`), so the latest contents are
    /// fetched. They match the returned item: a file's contents never change under the same node handle.
    func fetchContents(
        for itemIdentifier: NSFileProviderItemIdentifier,
        version requestedVersion: NSFileProviderItemVersion?,
        request: NSFileProviderRequest,
        completionHandler: @escaping (URL?, NSFileProviderItem?, (any Error)?) -> Void
    ) -> Progress {
        // Marked as a file download so that the progress can be described in bytes, e.g. "12 MB of 45 MB".
        let progress = Progress()
        progress.kind = .file
        progress.fileOperationKind = .downloading
        let itemUseCase = itemUseCase
        let contentUseCase = contentUseCase
        let temporaryDirectory = Result { try temporaryDirectoryURL() }
        let completion = UncheckedSendableCompletion(completionHandler)
        let task = Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                let item = try itemUseCase.item(for: itemIdentifier)
                progress.totalUnitCount = Int64(item.node.size)

                let label = "fetchContents \(itemIdentifier.rawValue) size=\(item.node.size)"
                FileProviderMemoryProbe.mark("\(label) begin")
                let sampling = FileProviderMemoryProbe.startSampling(label) {
                    "progress=\(progress.completedUnitCount)/\(progress.totalUnitCount)"
                }
                defer { sampling.cancel() }

                let url = try await contentUseCase.downloadContents(of: item, into: try temporaryDirectory.get()) {
                    progress.completedUnitCount = Int64($0)
                }
                FileProviderMemoryProbe.mark("\(label) finished")
                completion.handler(url, ReplicatedFileProviderItem(entity: item), nil)
            } catch {
                FileProviderMemoryProbe.mark("fetchContents \(itemIdentifier.rawValue) failed")
                // The system cancels the progress when the user cancels, or when the download stops making
                // progress for too long, and then expects `userCancelled`.
                guard !Task.isCancelled else {
                    MEGALogDebug("[Picker] Fetching the contents of \(itemIdentifier.rawValue) was cancelled")
                    completion.handler(nil, nil, CocoaError(.userCancelled))
                    return
                }
                MEGALogError("[Picker] Can't fetch the contents of \(itemIdentifier.rawValue): \(error)")
                completion.handler(nil, nil, FileProviderExtension.fileProviderError(for: error))
            }
        }
        progress.cancellationHandler = { task.cancel() }
        return progress
    }

    // MARK: - Changes from Files

    func createItem(
        basedOn itemTemplate: NSFileProviderItem,
        fields: NSFileProviderItemFields,
        contents url: URL?,
        options: NSFileProviderCreateItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        MEGALogError("[Picker] createItem is not supported yet: \(itemTemplate.filename) in \(itemTemplate.parentItemIdentifier.rawValue)")
        completionHandler(nil, [], false, CocoaError(.featureUnsupported))
        return Progress()
    }

    func modifyItem(
        _ item: NSFileProviderItem,
        baseVersion version: NSFileProviderItemVersion,
        changedFields: NSFileProviderItemFields,
        contents newContents: URL?,
        options: NSFileProviderModifyItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        guard changedFields.isSubset(of: Self.unsupportedFields) else {
            MEGALogError("[Picker] modifyItem is not supported yet: \(item.itemIdentifier.rawValue), fields \(changedFields.rawValue)")
            completionHandler(nil, [], false, CocoaError(.featureUnsupported))
            return Progress()
        }

        // Returning every changed field as still pending tells the system the fields are unsupported, so it stops
        // sending them for this item until the item changes. Failing instead shows up in Files as an error on the
        // file, which is what opening a file used to do.
        // Nothing changes in MEGA, so the item as the system knows it is still current. Returning it spares a
        // login and fetchNodes when the extension was only launched for this call.
        completionHandler(item, changedFields, false, nil)
        return Progress()
    }

    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        MEGALogError("[Picker] deleteItem is not supported yet: \(identifier.rawValue)")
        completionHandler(CocoaError(.featureUnsupported))
        return Progress()
    }

    // MARK: - Enumeration

    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator {
        // A domain can outlive the session, e.g. when the app is killed before its logout removed the domain.
        guard credentialUseCase.hasSession() else {
            throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
        }
        guard !credentialUseCase.isPasscodeEnabled() else {
            throw FileProviderSession.passcodeEnabledError
        }
        guard containerItemIdentifier != .workingSet else {
            return workingSetEnumerator
        }

        // The system asks for an enumerator of every folder it shows, which is when the folder is compared.
        let folderComparisonUseCase = folderComparisonUseCase
        let nodeUpdatesUseCase = nodeUpdatesUseCase
        Task {
            await NodeUpdatesCoordinator.shared.startQueueing(using: nodeUpdatesUseCase)
            await FolderComparisonCoordinator.shared.compareChildren(of: containerItemIdentifier, using: folderComparisonUseCase)
        }
        return ReplicatedFileProviderEnumerator(
            containerIdentifier: containerItemIdentifier,
            itemUseCase: itemUseCase,
            enumerationSnapshotUseCase: enumerationSnapshotUseCase
        )
    }

    // MARK: - Private

    /// Where downloads go: the system only takes contents from the volume of the domain's files.
    private func temporaryDirectoryURL() throws -> URL {
        guard let manager = NSFileProviderManager(for: domain) else {
            throw NSFileProviderError(.providerNotFound)
        }
        return try manager.temporaryDirectoryURL()
    }

    private func copyDatabasesFromMainApp() {
        CopyDataBasesUseCase(repo: CopyDataBasesRepository.nodeDatabaseGatedRepo).copyFromMainApp { result in
            switch result {
            case .success:
                MEGALogDebug("[Picker] Databases from main app copied")
            case .failure(let error):
                MEGALogError("[Picker] Error copying databases from main app: \(error)")
            }
        }
    }
}

/// Carries a completion handler from the system into a `Task`. The system never calls the handler itself and the
/// task calls it exactly once, so it is never used concurrently even though its type is not `Sendable`.
struct UncheckedSendableCompletion<Handler>: @unchecked Sendable {
    let handler: Handler

    init(_ handler: Handler) {
        self.handler = handler
    }
}
