import FileProvider
import MEGADomain

/// Uploads the files created and edited in Files to the cloud drive. Each item returned is recorded in its parent's
/// snapshot, like `FileProviderItemActionUseCase` does.
public protocol FileProviderUploadUseCaseProtocol: Sendable {
    /// Uploads a file created in Files into a folder. Cancelling the calling task cancels the upload. When a file of
    /// that name with other contents is in the folder, the file is uploaded under a free name, so that neither
    /// replaces the other: the system knows of no file there, or holds a copy it re-imports that may be stale.
    func createFile(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        contentsAt url: URL?,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> FileProviderItemEntity?

    /// Renames and moves a file like `FileProviderItemActionUseCase.modifyItem(_:name:parentIdentifier:)`, then
    /// uploads its new contents under the name and in the folder it then has. Cancelling the calling task cancels the upload.
    func uploadContents(
        of identifier: NSFileProviderItemIdentifier,
        at url: URL,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> FileProviderItemEntity
}

public struct FileProviderUploadUseCase: FileProviderUploadUseCaseProtocol {
    private let itemUseCase: any FileProviderItemUseCaseProtocol
    private let itemActionUseCase: any FileProviderItemActionUseCaseProtocol
    private let nodeRepo: any NodeRepositoryProtocol
    private let uploadRepo: any FileProviderUploadRepositoryProtocol
    private let nodeCoordinatesRepo: any NodeCoordinatesRepositoryProtocol
    private let snapshotRepo: any FileProviderSnapshotRepositoryProtocol

    public init(
        itemUseCase: any FileProviderItemUseCaseProtocol,
        itemActionUseCase: any FileProviderItemActionUseCaseProtocol,
        nodeRepo: any NodeRepositoryProtocol,
        uploadRepo: any FileProviderUploadRepositoryProtocol,
        nodeCoordinatesRepo: any NodeCoordinatesRepositoryProtocol,
        snapshotRepo: any FileProviderSnapshotRepositoryProtocol
    ) {
        self.itemUseCase = itemUseCase
        self.itemActionUseCase = itemActionUseCase
        self.nodeRepo = nodeRepo
        self.uploadRepo = uploadRepo
        self.nodeCoordinatesRepo = nodeCoordinatesRepo
        self.snapshotRepo = snapshotRepo
    }

    public func createFile(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        contentsAt url: URL?,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> FileProviderItemEntity? {
        let parent = try itemUseCase.item(for: parentIdentifier).node
        guard parent.isFolder else {
            throw NSFileProviderError(.noSuchItem)
        }
        let file: NodeEntity
        if let url {
            let uploadName = await freeName(for: name, in: parent, contentsAt: url, modificationDate: modificationDate)
            file = try await uploadRepo.upload(fileAt: url, named: uploadName, to: parent, modificationDate: modificationDate, progress: progress)
        } else {
            guard let existingFile = nodeRepo.childNodeNamed(name: name, in: parent.handle), existingFile.isFile else {
                return nil
            }
            file = existingFile
        }
        let item = try itemUseCase.item(for: NSFileProviderItemIdentifier(file.base64Handle))
        await record(item, replacing: nil)
        return item
    }

    public func uploadContents(
        of identifier: NSFileProviderItemIdentifier,
        at url: URL,
        name: String?,
        parentIdentifier: NSFileProviderItemIdentifier?,
        modificationDate: Date?,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> FileProviderItemEntity {
        let item = try await itemActionUseCase.modifyItem(identifier, name: name, parentIdentifier: parentIdentifier)
        guard item.node.isFile else {
            throw CocoaError(.featureUnsupported)
        }
        // The node's own name and parent, which the cloud drive may have changed since the system last saw them:
        // the upload becomes a new version only of a file of that name in that folder.
        let parent = try itemUseCase.item(for: item.parentIdentifier).node
        let file = try await uploadRepo.upload(
            fileAt: url,
            named: item.node.name,
            to: parent,
            modificationDate: modificationDate,
            progress: progress
        )
        let uploadedItem = try itemUseCase.item(for: NSFileProviderItemIdentifier(file.base64Handle))
        await copyCoordinates(of: item, to: uploadedItem)
        await record(uploadedItem, replacing: item.identifier)
        return uploadedItem
    }

    // MARK: - Private

    /// `name`, or the first of "name (1).ext", "name (2).ext"… that no file in the folder has. An upload under the
    /// name of a file in the folder becomes a new version of that file.
    private func freeName(for name: String, in folder: NodeEntity, contentsAt url: URL, modificationDate: Date?) async -> String {
        guard let existingFile = await nodeRepo.childNode(parent: folder, name: name, type: .file) else {
            return name
        }
        if let fingerprint = uploadRepo.fingerprint(ofFileAt: url, modificationDate: modificationDate), existingFile.fingerprint == fingerprint {
            return name
        }
        let baseName = (name as NSString).deletingPathExtension
        let pathExtension = (name as NSString).pathExtension
        var counter = 1
        while true {
            let numberedName = "\(baseName) (\(counter))"
            let candidate = pathExtension.isEmpty ? numberedName : "\(numberedName).\(pathExtension)"
            if await nodeRepo.childNode(parent: folder, name: candidate, type: .file) == nil {
                return candidate
            }
            counter += 1
        }
    }

    /// Gives a new version the location the former one had, as the legacy extension does. Best effort: the upload
    /// was made.
    private func copyCoordinates(of formerItem: FileProviderItemEntity, to item: FileProviderItemEntity) async {
        guard item.identifier != formerItem.identifier,
              let latitude = formerItem.node.latitude,
              let longitude = formerItem.node.longitude else {
            return
        }
        try? await nodeCoordinatesRepo.setUnshareableNodeCoordinates(item.node, latitude: latitude, longitude: longitude)
    }

    /// Records the item in its parent's snapshot, in place of the former version of the file. Best effort, like in
    /// `FileProviderItemActionUseCase`.
    private func record(_ item: FileProviderItemEntity, replacing formerIdentifier: NSFileProviderItemIdentifier?) async {
        let versionHash = item.versionHash
        try? await snapshotRepo.updateSnapshot(of: item.parentIdentifier) { snapshot in
            if let formerIdentifier {
                snapshot?.versionHashes[formerIdentifier] = nil
            }
            snapshot?.versionHashes[item.identifier] = versionHash
        }
    }
}
