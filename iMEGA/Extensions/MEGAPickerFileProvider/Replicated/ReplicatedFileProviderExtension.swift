@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGAPickerFileProviderRepo
import MEGARepo
import UniformTypeIdentifiers
import os

/// Entry point of the File Provider extension on `NSFileProviderReplicatedExtension`.
///
/// Only used when the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting points at it; `FileProviderExtension`
/// stays the shipping implementation until the switch. For now it serves browsing, downloading, uploading, creating
/// folders, renaming, moving and deleting, and keeps what Files shows in step with remote changes.
final class ReplicatedFileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    /// The changes `modifyItem` makes to the node without new contents. The others have nowhere to be kept in MEGA,
    /// such as the last used date, which the system sets whenever a file is opened, and a folder's modification date,
    /// which it sets whenever a file is added to the folder.
    private static let appliedFields: NSFileProviderItemFields = [.filename, .parentItemIdentifier]

    /// The fields an upload applies, along with the contents: the node takes the file's modification date. The others,
    /// such as extended attributes, stay pending, or the system would clear them on disk to match the returned item.
    private static let uploadedFields: NSFileProviderItemFields = appliedFields.union([.contents, .contentModificationDate])

    /// The domains whose leftover downloads this process has removed. Only the first instance for a domain removes
    /// them: a later one could delete a download that an earlier instance has finished but the system hasn't taken.
    private static let domainsWithoutLeftoverDownloads = OSAllocatedUnfairLock<Set<String>>(initialState: [])

    private let domain: NSFileProviderDomain
    private let inFlightThumbnailLoads = InFlightThumbnailLoads()
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

    /// Built on every use for the same reason as `itemUseCase`.
    private var uploadUseCase: some FileProviderUploadUseCaseProtocol {
        FileProviderUploadUseCase(
            itemUseCase: itemUseCase,
            itemActionUseCase: itemActionUseCase,
            nodeRepo: NodeRepository.newRepo,
            uploadRepo: FileProviderUploadRepository.newRepo,
            nodeCoordinatesRepo: NodeCoordinatesRepository.newRepo,
            snapshotRepo: FileProviderSnapshotRepository.newRepo
        )
    }

    /// Built on every use for the same reason as `itemUseCase`.
    private var thumbnailUseCase: some FileProviderThumbnailUseCaseProtocol {
        FileProviderThumbnailUseCase(
            itemUseCase: itemUseCase,
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            inFlightLoads: inFlightThumbnailLoads
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
        removeLeftoverDownloads()
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
            } catch let error as NSFileProviderError where error.code == .noSuchItem {
                // Expected after every upload of a new version: the system looks the former version up once.
                MEGALogDebug("[Picker] No item \(identifier.rawValue)")
                completion.handler(nil, error)
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
        let contentType = itemTemplate.contentType ?? .data
        // A package is a folder on disk, and a symbolic link has no contents: neither can be a file in MEGA. Excluded,
        // the item stays on disk without being synced.
        guard !contentType.conforms(to: .package), !contentType.conforms(to: .symbolicLink) else {
            MEGALogError("[Picker] Not syncing an item of type \(contentType.identifier) in \(parentIdentifier.rawValue)")
            completionHandler(nil, [], false, NSFileProviderError(.excludedFromSync))
            return Progress()
        }
        // Any other directory, which uploaded as a file would make the SDK upload its whole tree.
        guard !contentType.conforms(to: .directory) else {
            return createFolder(basedOn: itemTemplate, options: options, completionHandler: completionHandler)
        }

        let uploadUseCase = uploadUseCase
        let name = itemTemplate.filename
        // A field the template doesn't list is undefined (see `NSFileProviderReplicatedExtension.h`).
        let modificationDate = fields.contains(.contentModificationDate) ? (itemTemplate.contentModificationDate ?? nil) : nil
        let pendingFields = fields.subtracting(Self.uploadedFields)
        return upload(contentsAt: url, label: "createItem in \(parentIdentifier.rawValue)", completionHandler: completionHandler) { progress in
            // A file uploaded under another name is returned with that name, and the system renames its copy.
            let item = try await uploadUseCase.createFile(
                named: name,
                in: parentIdentifier,
                contentsAt: url,
                modificationDate: modificationDate,
                progress: progress
            )
            // Without an item, the system removes the file it re-imported, which has no contents anyway.
            return (item, pendingFields)
        }
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
        let name = changedFields.contains(.filename) ? item.filename : nil
        let parentIdentifier = changedFields.contains(.parentItemIdentifier) ? item.parentItemIdentifier : nil
        guard changedFields.contains(.contents), let newContents else {
            return modifyMetadata(
                of: identifier,
                name: name,
                parentIdentifier: parentIdentifier,
                changedFields: changedFields,
                completionHandler: completionHandler
            )
        }

        let uploadUseCase = uploadUseCase
        let modificationDate = item.contentModificationDate ?? nil
        let unappliedFields = changedFields.subtracting(Self.uploadedFields)
        return upload(contentsAt: newContents, label: "modifyItem \(identifier.rawValue)", completionHandler: completionHandler) { progress in
            // The new version has a new identifier, which the system takes over the local contents with.
            let uploadedItem = try await uploadUseCase.uploadContents(
                of: identifier,
                at: newContents,
                name: name,
                parentIdentifier: parentIdentifier,
                modificationDate: modificationDate,
                progress: progress
            )
            return (uploadedItem, Self.pendingFields(unappliedFields, requestedName: name, of: uploadedItem))
        }
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

    private func createFolder(
        basedOn itemTemplate: NSFileProviderItem,
        options: NSFileProviderCreateItemOptions,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        let parentIdentifier = itemTemplate.parentItemIdentifier
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

    private func modifyMetadata(
        of identifier: NSFileProviderItemIdentifier,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?,
        changedFields: NSFileProviderItemFields,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void
    ) -> Progress {
        let unappliedFields = changedFields.subtracting(Self.appliedFields)
        let itemActionUseCase = itemActionUseCase
        let completion = UncheckedSendableCompletion(completionHandler)
        // Sendable, so that its captures are checked by type: the region-based isolation checker of Xcode 26 fails on
        // them. `Self` would capture `self` here, hence the type name.
        Task { @Sendable in
            do {
                try await FileProviderSession.shared.ensureReady()
                let modifiedItem = try await itemActionUseCase.modifyItem(identifier, name: name, parentIdentifier: parentIdentifier)
                let pendingFields = ReplicatedFileProviderExtension.pendingFields(unappliedFields, requestedName: name, of: modifiedItem)
                completion.handler(ReplicatedFileProviderItem(entity: modifiedItem), pendingFields, false, nil)
            } catch {
                MEGALogError("[Picker] Can't modify the item \(identifier.rawValue), fields \(changedFields.rawValue): \(error)")
                completion.handler(nil, [], false, FileProviderExtension.fileProviderError(for: error))
            }
        }
        return Progress()
    }

    /// Runs the upload of `createItem` or `modifyItem`, which returns the item to complete with and its pending fields.
    private func upload(
        contentsAt url: URL?,
        label: String,
        completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, (any Error)?) -> Void,
        operation: @escaping @Sendable (
            _ progress: @escaping @Sendable (Int) -> Void
        ) async throws -> (FileProviderItemEntity?, NSFileProviderItemFields)
    ) -> Progress {
        // Marked as a file upload so that the progress can be described in bytes, e.g. "12 MB of 45 MB".
        let size = url.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize } ?? 0
        let progress = Progress(totalUnitCount: Int64(size))
        progress.kind = .file
        progress.fileOperationKind = .uploading
        let completion = UncheckedSendableCompletion(completionHandler)
        let task = Task {
            FileProviderMemoryProbe.mark("\(label) size=\(size) begin")
            let sampling = FileProviderMemoryProbe.startSampling(label) {
                "progress=\(progress.completedUnitCount)/\(progress.totalUnitCount)"
            }
            defer { sampling.cancel() }
            do {
                try await FileProviderSession.shared.ensureReady()
                let (item, pendingFields) = try await operation { progress.completedUnitCount = Int64($0) }
                FileProviderMemoryProbe.mark("\(label) finished")
                completion.handler(item.map { ReplicatedFileProviderItem(entity: $0) }, pendingFields, false, nil)
            } catch {
                FileProviderMemoryProbe.mark("\(label) failed")
                guard !Task.isCancelled else {
                    MEGALogDebug("[Picker] \(label) was cancelled")
                    completion.handler(nil, [], false, CocoaError(.userCancelled))
                    return
                }
                MEGALogError("[Picker] \(label) failed: \(error)")
                completion.handler(nil, [], false, FileProviderExtension.fileProviderError(for: error))
            }
        }
        progress.cancellationHandler = { task.cancel() }
        return progress
    }

    /// `unappliedFields`, along with the name when it was not applied, so that the system keeps its own name on disk.
    private static func pendingFields(
        _ unappliedFields: NSFileProviderItemFields,
        requestedName: String?,
        of item: FileProviderItemEntity
    ) -> NSFileProviderItemFields {
        requestedName == nil || item.node.name == requestedName ? unappliedFields : unappliedFields.union(.filename)
    }

    /// Where downloads go: the system only takes contents from the volume of the domain's files.
    private func temporaryDirectoryURL() throws -> URL {
        guard let manager = NSFileProviderManager(for: domain) else {
            throw NSFileProviderError(.providerNotFound)
        }
        return try manager.temporaryDirectoryURL()
    }

    /// Deletes the downloads left in the temporary directory when an earlier process or the system ended before the system
    /// took them, which the extension is responsible for (see `fetchContents` in `NSFileProviderReplicatedExtension.h`).
    /// Runs synchronously from `init`, so no download of this process is there yet. Dates can't tell the two apart:
    /// the SDK sets a finished download's modification date, and with it the creation date, to the node's.
    private func removeLeftoverDownloads() {
        let domainIdentifier = domain.identifier.rawValue
        let directory: URL
        do {
            directory = try temporaryDirectoryURL()
        } catch {
            MEGALogError("[Picker] Can't find the temporary directory to remove leftover downloads: \(error)")
            return
        }
        Self.domainsWithoutLeftoverDownloads.withLock { domainIdentifiers in
            guard domainIdentifiers.insert(domainIdentifier).inserted else { return }
            let fileManager = FileManager.default
            let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            for file in files {
                do {
                    try fileManager.removeItem(at: file)
                    MEGALogDebug("[Picker] Removed the leftover download \(file.lastPathComponent)")
                } catch {
                    MEGALogError("[Picker] Can't remove the leftover download \(file.lastPathComponent): \(error)")
                }
            }
        }
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

// MARK: - NSFileProviderThumbnailing

extension ReplicatedFileProviderExtension: NSFileProviderThumbnailing {
    /// Every item gets the 200px thumbnail MEGA keeps for it, whatever `size` the system asks for.
    func fetchThumbnails(
        for itemIdentifiers: [NSFileProviderItemIdentifier],
        requestedSize size: CGSize,
        perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, (any Error)?) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        let thumbnailUseCase = thumbnailUseCase
        let perThumbnailCompletion = UncheckedSendableCompletion(perThumbnailCompletionHandler)
        let completion = UncheckedSendableCompletion(completionHandler)
        let task = Task {
            do {
                try await FileProviderSession.shared.ensureReady()
            } catch {
                // Applies to every item. A `nil` thumbnail instead would be kept as the item having none.
                MEGALogError("[Picker] Can't fetch thumbnails: \(error)")
                completion.handler(FileProviderExtension.fileProviderError(for: error))
                return
            }
            await thumbnailUseCase.loadThumbnails(for: itemIdentifiers) { identifier, result in
                switch result {
                case .success(let data):
                    perThumbnailCompletion.handler(identifier, data, nil)
                case .failure(let error):
                    MEGALogError("[Picker] Can't fetch the thumbnail of \(identifier.rawValue): \(error)")
                    perThumbnailCompletion.handler(identifier, nil, FileProviderExtension.fileProviderError(for: error))
                }
                progress.completedUnitCount += 1
            }
            // The error applies to the items not reported once the system cancelled the progress.
            completion.handler(Task.isCancelled ? CocoaError(.userCancelled) : nil)
        }
        progress.cancellationHandler = { task.cancel() }
        return progress
    }
}

/// Carries a completion handler from the system into a `Task`. The system never calls the handler itself and the
/// task calls it from one place at a time, so it is never used concurrently even though its type is not `Sendable`.
struct UncheckedSendableCompletion<Handler>: @unchecked Sendable {
    let handler: Handler

    init(_ handler: Handler) {
        self.handler = handler
    }
}
