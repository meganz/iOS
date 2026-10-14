@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGAPickerFileProviderRepo
import MEGARepo
import UniformTypeIdentifiers

/// Entry point of the File Provider extension on `NSFileProviderReplicatedExtension`.
///
/// Only used when the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting points at it; `FileProviderExtension`
/// stays the shipping implementation until the switch. For now it serves browsing, downloading, creating folders,
/// renaming, moving and deleting, and keeps what Files shows in step with remote changes.
final class ReplicatedFileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    /// The changes `modifyItem` makes to the node. The others have nowhere to be kept in MEGA, such as the last used
    /// date, which the system sets whenever a file is opened, and a folder's modification date, which it sets whenever
    /// a file is added to the folder.
    private static let appliedFields: NSFileProviderItemFields = [.filename, .parentItemIdentifier]

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

    /// Built on every use for the same reason as `itemUseCase`.
    private var itemActionUseCase: some FileProviderItemActionUseCaseProtocol {
        FileProviderItemActionUseCase(
            itemUseCase: itemUseCase,
            nodeRepo: NodeRepository.newRepo,
            nodeActionRepo: NodeActionRepository.newRepo,
            snapshotRepo: FileProviderSnapshotRepository.newRepo
        )
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
        let parentIdentifier = itemTemplate.parentItemIdentifier
        guard itemTemplate.contentType == .folder else {
            MEGALogError("[Picker] Creating a file is not supported yet, in \(parentIdentifier.rawValue)")
            completionHandler(nil, [], false, CocoaError(.featureUnsupported))
            return Progress()
        }

        let itemActionUseCase = itemActionUseCase
        let name = itemTemplate.filename
        let reusesExistingFolder = options.contains(.mayAlreadyExist)
        let completion = UncheckedSendableCompletion(completionHandler)
        Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                let item = try await itemActionUseCase.createFolder(named: name, in: parentIdentifier, reusesExistingFolder: reusesExistingFolder)
                // The other fields, such as the dates, are taken from the folder MEGA created.
                completion.handler(ReplicatedFileProviderItem(entity: item), [], false, nil)
            } catch {
                MEGALogError("[Picker] Can't create a folder in \(parentIdentifier.rawValue): \(error)")
                completion.handler(nil, [], false, FileProviderExtension.fileProviderError(for: error))
            }
        }
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
        let identifier = item.itemIdentifier
        guard !changedFields.contains(.contents) else {
            MEGALogError("[Picker] Changing the contents is not supported yet: \(identifier.rawValue), fields \(changedFields.rawValue)")
            completionHandler(nil, [], false, CocoaError(.featureUnsupported))
            return Progress()
        }

        // Returning a field as still pending every time tells the system it is unsupported, so it stops sending it
        // for this item until the item changes. Failing instead shows up in Files as an error on the item.
        let unappliedFields = changedFields.subtracting(Self.appliedFields)
        let name = changedFields.contains(.filename) ? item.filename : nil
        let parentIdentifier = changedFields.contains(.parentItemIdentifier) ? item.parentItemIdentifier : nil
        let itemActionUseCase = itemActionUseCase
        let completion = UncheckedSendableCompletion(completionHandler)
        Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                // The item passed in has an empty version, which returned as is would make the system drop the local
                // contents and download them again on the next open, so the item is built from the node.
                let modifiedItem = try await itemActionUseCase.modifyItem(identifier, name: name, parentIdentifier: parentIdentifier)
                // A name that was not applied stays pending too, so the system keeps its own name on disk.
                let pendingFields = name == nil || modifiedItem.node.name == name ? unappliedFields : unappliedFields.union(.filename)
                completion.handler(ReplicatedFileProviderItem(entity: modifiedItem), pendingFields, false, nil)
            } catch {
                MEGALogError("[Picker] Can't modify the item \(identifier.rawValue), fields \(changedFields.rawValue): \(error)")
                completion.handler(nil, [], false, FileProviderExtension.fileProviderError(for: error))
            }
        }
        return Progress()
    }

    func deleteItem(
        identifier: NSFileProviderItemIdentifier,
        baseVersion version: NSFileProviderItemVersion,
        options: NSFileProviderDeleteItemOptions,
        request: NSFileProviderRequest,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        let itemActionUseCase = itemActionUseCase
        let recursive = options.contains(.recursive)
        let completion = UncheckedSendableCompletion(completionHandler)
        Task {
            do {
                try await FileProviderSession.shared.ensureReady()
                try await itemActionUseCase.deleteItem(identifier, recursive: recursive)
                completion.handler(nil)
            } catch {
                MEGALogError("[Picker] Can't delete the item \(identifier.rawValue): \(error)")
                completion.handler(FileProviderExtension.fileProviderError(for: error))
            }
        }
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
