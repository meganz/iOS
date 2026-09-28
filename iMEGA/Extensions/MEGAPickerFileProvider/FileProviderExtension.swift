@preconcurrency import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGARepo

final class FileProviderExtension: NSFileProviderExtension {
    private var credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)
    private lazy var nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
    private lazy var transferUseCase = TransferUseCase(
        repo: TransferRepository.newRepo,
        metadataUseCase: metadataUseCase,
        nodeDataRepository: NodeDataRepository.newRepo
    )
    private lazy var nodeAttributeUseCase = NodeAttributeUseCase(repo: NodeAttributeRepository.newRepo)
    private var thumbnailUseCase = ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
    private let fileProviderEnumeratorUseCase = FileProviderEnumeratorUseCase(
        filesSearchRepo: FilesSearchRepository.newRepo,
        nodeRepo: NodeRepository.newRepo,
        megaHandleRepo: MEGAHandleRepository.newRepo)
    
    private lazy var metadataUseCase = MetadataUseCase(
        metadataRepository: MetadataRepository(),
        fileSystemRepository: FileSystemRepository.sharedRepo,
        fileExtensionRepository: FileExtensionRepository(),
        nodeCoordinatesRepository: NodeCoordinatesRepository.newRepo
    )
    
    override init() {
        super.init()
        AppEnvironmentConfigurator.configAppEnvironment()
#if DEBUG
        MEGASdk.setLogLevel(.max)
#endif
        MEGASdk.setLogToConsole(true)
        copyDatabasesFromMainApp()
    }
    
    // MARK: - Working with items and persistent identifiers
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        Self.persistentIdentifier(at: url)
    }

    private static func persistentIdentifier(at url: URL) -> NSFileProviderItemIdentifier? {
        var localRelativePath: String
        // This is a bit tricky. As an identifier, we use the "path" in MEGA ex: /folder/subfolder/file,
        // We create "placeholders" and files/folders in NSFileProviderManager.default.documentStorageURL (+ identifier) appending the identifier (path in MEGA)
        // This method is called from different places and the URL may contain "/private" or not, documentStorageURL includes "/private": file:///private/var/mobile/Containers/Shared/AppGroup/E987FA27-C16B-424A-8148-865F8AE2E932/File%20Provider%20Storage/
        // When calling it from itemChanged, url is similar to (it doesn't include "/private"): file:///var/mobile/Containers/Shared/AppGroup/2F61E5F1-174B-434D-A51C-0A7019C3AD8D/File%20Provider%20Storage/
        // When calling it from providingPlaceholder or startProvidingItem url includes "/private": file:///private/var/mobile/Containers/Shared/AppGroup/2F61E5F1-174B-434D-A51C-0A7019C3AD8D/File%20Provider%20Storage/
        // This is the reason of the following code, getting the correct identifier
        if url.path.contains("/private") {
            localRelativePath = url.path.replacingOccurrences(of: NSFileProviderManager.default.documentStorageURL.path, with: "")
        } else {
            localRelativePath = url.path.replacingOccurrences(of: NSFileProviderManager.default.documentStorageURL.path.replacingOccurrences(of: "/private", with: ""), with: "")
        }
        var nodePath: String
        if localRelativePath.hasPrefix("//") {
            nodePath = String(localRelativePath.dropFirst())
        } else {
            nodePath = localRelativePath
        }
        guard let node = MEGASdk.shared.node(forPath: nodePath),
              let base64Handle = node.base64Handle else {
            return nil
        }
        return NSFileProviderItemIdentifier(base64Handle)
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
        guard let node = node(for: identifier),
              let path = nodeAttributeUseCase.pathFor(node: node) else {
            return nil
        }
        
        let url: URL? = NSFileProviderManager.default.documentStorageURL.appendingPathComponent(path)
        return url
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        guard let node = node(for: identifier) else {
            throw NSError.fileProviderErrorForNonExistentItem(withIdentifier: identifier)
        }
        return FileProviderItem(node: node)
    }
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> any NSFileProviderEnumerator {
        guard credentialUseCase.hasSession() else {
            throw NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue)
        }
        
        // Kept here as well as in `FileProviderSession.ensureReady()`: this method is synchronous and cannot
        // await, and failing before the enumerator is built keeps Files from waiting on an enumeration that
        // is going to be rejected anyway.
        guard !credentialUseCase.isPasscodeEnabled() else {
            throw FileProviderSession.passcodeEnabledError
        }
        
        return FileProviderEnumerator(
            identifier: containerItemIdentifier,
            fileProviderEnumeratorUseCase: fileProviderEnumeratorUseCase)
    }
    
    // MARK: - Managing shared files
    
    override func providePlaceholder(at url: URL) async throws {
        try await Self.ensureSessionReady()
        guard let identifier = persistentIdentifierForItem(at: url) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let fileProviderItem = try item(for: identifier)
        let placeholderDirectoryUrl = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: placeholderDirectoryUrl.path) {
            try FileManager.default.createDirectory(at: placeholderDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
        }
        let placeholderURL = NSFileProviderManager.placeholderURL(for: url)
        try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: fileProviderItem)
    }
    
    override func startProvidingItem(at url: URL) async throws {
        try await Self.ensureSessionReady()
        guard let identifier = persistentIdentifierForItem(at: url),
              let node = node(for: identifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        // A directory has no contents to provide: its children come from enumeration. Starting an SDK
        // download for a folder node recursively downloads everything inside it and collides with the
        // user's own per-file downloads (the SDK rejects a second transfer to the same path).
        guard node.isFile else { return }

        let fileProviderItem = try item(for: identifier)
        let isDownloaded = fileProviderItem.isDownloaded ?? false
        guard !isDownloaded else { return }

        // Large files outlive fileproviderd's patience: Files reports a failure while the transfer keeps
        // running. Joining the in-flight download and signalling once it lands keeps the item consistent
        // for the retry and lets Files refresh the downloaded state on its own.
        let parentItemIdentifier = fileProviderItem.parentItemIdentifier
        do {
            try await FileProviderDownloadCoordinator.shared.download(node: node, to: url, using: transferUseCase) {
                await FileProviderExtension.signalEnumerators(for: [identifier, parentItemIdentifier])
            }
        } catch {
            throw FileProviderExtension.fileProviderError(for: error)
        }
    }
    
    override func itemChanged(at url: URL) {
        Task { [transferUseCase] in
            // Every lookup below goes through the SDK node tree, which a freshly launched extension process
            // does not have yet. Resolving them before the session is ready made all four guards fail and the
            // user's local edit was silently dropped instead of uploaded. Nothing here can be resolved outside
            // the Task, so the whole body waits for the session first.
            do {
                try await FileProviderSession.shared.ensureReady()
            } catch {
                MEGALogError("[Picker] Can't upload the change at \(url): \(error)")
                return
            }

            guard let identifier = FileProviderExtension.persistentIdentifier(at: url),
                  let node = FileProviderExtension.node(for: identifier),
                  FileManager.default.fileExists(atPath: url.path),
                  let parentNode = MEGASdk.shared.node(forHandle: node.parentHandle) else {
                return
            }
            let parentItemIdentifier = FileProviderItem(node: node).parentItemIdentifier

            guard let transferEntity = try? await transferUseCase.uploadFile(at: url, to: parentNode.toNodeEntity(), startHandler: {  _ in
                NSFileProviderManager.default.signalEnumerator(for: identifier) { error in
                    if let error {
                        MEGALogError("Error signaling item: \(error)")
                    }
                }
                NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier) { error in
                    if let error {
                        MEGALogError("Error signaling item: \(error)")
                    }
                }
            }) else { return }
            
            do {
                try await NSFileProviderManager.default.signalEnumerator(for: identifier)
                try await NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier)
            } catch {
                MEGALogError("Error signaling item: \(error)")
            }
            if let longitude = node.longitude,
               let latitude = node.latitude {
                MEGASdk.shared.setUnshareableCoordinatesForNodeHandle(transferEntity.nodeHandle, latitude: latitude, longitude: longitude)
            }
        }
    }
    
    override func stopProvidingItem(at url: URL) {
        MEGALogDebug("[Picker] stopProvidingItem at \(url)")
    }
    
    // MARK: - Handling Actions
    
    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let parentNode = node(for: parentItemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let node = try await nodeActionUseCase.createFolder(name: directoryName, parent: parentNode)
        return FileProviderItem(node: node)
    }
    
    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let renamedNode = try await nodeActionUseCase.rename(node: node, name: itemName)
        
        return FileProviderItem(node: renamedNode)
    }
    
    override func trashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.trash(node: node)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func untrashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier?) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.untrash(node: node)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        try await nodeActionUseCase.delete(node: node)
    }
    
    override func reparentItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemWithIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, newName: String?) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let parentNode = node(for: parentItemIdentifier),
              let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let movedNode = try await nodeActionUseCase.move(node: node, toParent: parentNode)
        
        return FileProviderItem(node: movedNode)
    }
    
    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let parentNode = node(for: parentItemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let transfer = try await transferUseCase.uploadFile(at: fileURL, to: parentNode, startHandler: {  _ in
            NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier) { error in
                if let error {
                    MEGALogError("Error signaling item: \(error)")
                }
            }
        })
        
        try await NSFileProviderManager.default.signalEnumerator(for: parentItemIdentifier)
        
        guard let node = MEGASdk.shared.node(forHandle: transfer.nodeHandle) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        return FileProviderItem(node: node.toNodeEntity())
    }
    
    override func setFavoriteRank(_ favoriteRank: NSNumber?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let fileProviderItem = FileProviderItem(node: node)
        
        fileProviderItem.favoriteRank = favoriteRank
        
        return fileProviderItem
    }
    
    override func setTagData(_ tagData: Data?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier) async throws -> NSFileProviderItem {
        try await Self.ensureSessionReady()
        guard let node = node(for: itemIdentifier) else {
            throw NSFileProviderError(.noSuchItem)
        }
        
        let fileProviderItem = FileProviderItem(node: node)
        
        fileProviderItem.tagData = tagData
        
        return fileProviderItem
    }
    
    // MARK: - Accessing thumbnails
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier],
                                  requestedSize size: CGSize,
                                  perThumbnailCompletionHandler: @Sendable @escaping (NSFileProviderItemIdentifier, Data?, (any Error)?) -> Void,
                                  completionHandler: @Sendable @escaping ((any Error)?) -> Void) -> Progress {
        
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        let maxConcurrentThumbnails = 3

        // `completionHandler` must run exactly once on every path, otherwise fileproviderd waits forever
        // and eventually kills the extension. Every per-item outcome, including cancellation, therefore goes
        // through `fetchThumbnail`; the parent task advances `progress`.
        Task { [thumbnailUseCase] in
            do {
                try await FileProviderExtension.ensureSessionReady()
            } catch {
                // Files caches a `nil` thumbnail as "this item has none" and never asks again, so a session
                // failure must surface as an error: that keeps the request retryable once the user is back in.
                itemIdentifiers.forEach { perThumbnailCompletionHandler($0, nil, error) }
                completionHandler(error)
                return
            }

            for batchStart in stride(from: 0, to: itemIdentifiers.count, by: maxConcurrentThumbnails) {
                guard !progress.isCancelled else { break }
                let batch = itemIdentifiers[batchStart..<min(batchStart + maxConcurrentThumbnails, itemIdentifiers.count)]
                await withTaskGroup(of: Void.self) { group in
                    for identifier in batch {
                        group.addTask {
                            await FileProviderExtension.fetchThumbnail(
                                for: identifier,
                                using: thumbnailUseCase,
                                progress: progress,
                                completion: perThumbnailCompletionHandler
                            )
                        }
                    }
                }
                // Advance the progress once per batch from the parent task: `completedUnitCount += 1` is a
                // read-modify-write and would lose updates when the child tasks race on it.
                progress.completedUnitCount += Int64(batch.count)
            }

            completionHandler(progress.isCancelled ? CocoaError(.userCancelled) : nil)
        }

        return progress
    }
    
    // MARK: - Private
    
    private func copyDatabasesFromMainApp() {
        let copyDataBasesUseCase = CopyDataBasesUseCase(repo: CopyDataBasesRepository.nodeDatabaseGatedRepo)
        
        copyDataBasesUseCase.copyFromMainApp { (result) in
            switch result {
            case .success:
                MEGALogDebug("[Picker] Databases from main app copied")
            case .failure(let error):
                MEGALogError("[Picker] Error copying databases from main app: \(error)")
            }
        }
    }
    
    private func node(for identifier: NSFileProviderItemIdentifier) -> NodeEntity? {
        Self.node(for: identifier)
    }

    private static func node(for identifier: NSFileProviderItemIdentifier) -> NodeEntity? {
        if identifier == NSFileProviderItemIdentifier.rootContainer {
            return MEGASdk.shared.rootNode?.toNodeEntity()
        }
        let base64Handle = identifier.rawValue
        let handle = MEGASdk.handle(forBase64Handle: base64Handle)
        guard let node = MEGASdk.shared.node(forHandle: handle) else {
            return nil
        }
        return node.toNodeEntity()
    }

    /// Logs in and fetches nodes if this process has not done it yet, mapping the failure to an error
    /// fileproviderd understands. `AuthRepository.login` surfaces a raw `MEGAError`, whose bridged domain is
    /// neither NSCocoaErrorDomain nor NSFileProviderErrorDomain, so it must never reach the system as-is.
    private static func ensureSessionReady() async throws {
        do {
            try await FileProviderSession.shared.ensureReady()
        } catch {
            throw fileProviderError(for: error)
        }
    }

    /// fileproviderd only understands NSCocoaErrorDomain and NSFileProviderErrorDomain; any other domain surfaces
    /// in Files as the generic "couldn't communicate with the helper application" alert.
    ///
    /// Unknown failures fall back to `serverUnreachable`, the closest "try again later" code available to a
    /// non-replicated extension. `cannotSynchronize` is not an option: it is a replicated-only (V3) code, and
    /// it tells the system the item is definitively broken and must not be retried until the item changes on
    /// disk or the extension is updated - the wrong contract for a transient login or transfer failure.
    static func fileProviderError(for error: any Error) -> any Error {
        // Errors that already live in a domain the system understands are passed through untouched. Wrapping
        // them would hide `notAuthenticated`, the one code Files acts on by prompting the user to sign in.
        let nsError = error as NSError
        guard nsError.domain != NSFileProviderErrorDomain, nsError.domain != NSCocoaErrorDomain else {
            return error
        }

        guard let transferError = error as? TransferErrorEntity else {
            return NSFileProviderError(.serverUnreachable, userInfo: [NSUnderlyingErrorKey: error])
        }
        switch transferError {
        case .cancelled:
            return CocoaError(.userCancelled)
        case .couldNotFindNodeByHandle, .couldNotFindNodeByLink:
            return NSFileProviderError(.noSuchItem)
        case .overquota:
            return NSFileProviderError(.insufficientQuota)
        default:
            return NSFileProviderError(.serverUnreachable, userInfo: [NSUnderlyingErrorKey: error])
        }
    }

    private static func signalEnumerators(for identifiers: [NSFileProviderItemIdentifier]) async {
        for identifier in identifiers {
            do {
                try await NSFileProviderManager.default.signalEnumerator(for: identifier)
            } catch {
                MEGALogError("[Picker] Error signaling enumerator for \(identifier.rawValue): \(error)")
            }
        }
    }

    private static func fetchThumbnail(
        for identifier: NSFileProviderItemIdentifier,
        using thumbnailUseCase: some ThumbnailUseCaseProtocol,
        progress: Progress,
        completion: @Sendable (NSFileProviderItemIdentifier, Data?, (any Error)?) -> Void
    ) async {
        guard let node = node(for: identifier) else {
            completion(identifier, nil, nil)
            return
        }
        do {
            let thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            guard !progress.isCancelled else {
                completion(identifier, nil, CocoaError(.userCancelled))
                return
            }
            let data = try Data(contentsOf: thumbnailEntity.url, options: .alwaysMapped)
            completion(identifier, data, nil)
        } catch let thumbnailError as ThumbnailErrorEntity {
            // Definitive: the node has no thumbnail attribute (or no longer exists). Files treats a `nil`
            // thumbnail as final and falls back to the generic icon, which is the right outcome here.
            // fileproviderd would also log a fault for this foreign error domain if it were passed through.
            MEGALogDebug("[Picker] No thumbnail for \(identifier.rawValue): \(thumbnailError)")
            completion(identifier, nil, nil)
        } catch {
            // Transient (network, SDK, file read): report an error in a domain fileproviderd accepts so Files
            // retries later instead of caching "no thumbnail" for good.
            completion(identifier, nil, fileProviderError(for: error))
        }
    }
}
