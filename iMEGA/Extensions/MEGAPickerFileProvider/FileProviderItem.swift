import FileProvider
import MEGAAppSDKRepo
import MEGADomain
import MEGAPickerFileProviderDomain
import MEGAPickerFileProviderRepo
import MEGARepo
import MEGASwift
import UniformTypeIdentifiers

final class FileProviderItem: NSObject, NSFileProviderItem {
    private let node: NodeEntity
    private let nodeAttributeUseCase: any NodeAttributeUseCaseProtocol
    private let fileProviderItemMetadataUseCase: any FileProviderItemMetadataUseCaseProtocol
    
    init(node: NodeEntity) {
        self.node = node
        self.nodeAttributeUseCase = NodeAttributeUseCase(repo: NodeAttributeRepository.newRepo)
        self.fileProviderItemMetadataUseCase = FileProviderItemMetadataUseCase(repository: FileProviderItemMetadataRepository.newRepo)
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        NSFileProviderItemIdentifier(rawValue: node.base64Handle.toItemIdentifier())
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        if MEGASdk.shared.rootNode?.handle == node.handle {
            return itemIdentifier
        }

        guard let parentBase64Handle = MEGASdk.base64Handle(forHandle: node.parentHandle) else {
            assertionFailure("Parent item identifier is needed")
            return NSFileProviderItemIdentifier("")
        }
        return NSFileProviderItemIdentifier(parentBase64Handle.toItemIdentifier())
    }
    
    var capabilities: NSFileProviderItemCapabilities {
        [.allowsReading, .allowsWriting, .allowsRenaming, .allowsReparenting, .allowsTrashing, .allowsDeleting]
    }
    
    var filename: String {
        node.name
    }
    
    var contentType: UTType {
        guard !node.isFolder else {
            return .folder
        }
        
        return UTType(filenameExtension: node.name.pathExtension) ?? .data
    }
    
    var childItemCount: NSNumber? {
        guard node.isFolder else {
            return nil
        }
        return nodeAttributeUseCase.numberChildrenFor(node: node) as NSNumber?
    }
    
    var documentSize: NSNumber? {
        NSNumber(value: node.size)
    }
    
    var creationDate: Date? {
        node.creationTime
    }
    
    var contentModificationDate: Date? {
        guard node.isFile else {
            return nil
        }
        return node.modificationTime
    }
    
    var isShared: Bool {
        node.isOutShare
    }
    
    var isTrashed: Bool {
        nodeAttributeUseCase.isInRubbishBin(node: node)
    }
    
    var isDownloaded: Bool {
        isFileInCloud()
    }

    /// Files draws a dashed cloud badge on items that are downloaded but not the most recent version. Without this
    /// the system assumes `false`, so every downloaded file kept the dashed badge. A local copy only counts as
    /// downloaded when its fingerprint matches the node, which by definition is the most recent version.
    var isMostRecentVersionDownloaded: Bool {
        isFileInCloud()
    }

    /// A node only exists in the MEGA tree once its upload has completed, so an item is uploaded unless a
    /// replacement upload for it is in flight (`itemChanged`). Files uses `isUploaded` for the cloud badge and
    /// treats an unimplemented value as `false`, which showed a "waiting to upload" dashed cloud on every
    /// downloaded item.
    var isUploaded: Bool {
        !isUploading
    }

    var isUploading: Bool {
        // `localURL()` returns nil for folders, which is what keeps every ancestor of an uploading file - and
        // the root container, whose node path is "/" - from reporting itself as uploading. A folder node only
        // exists in the cloud once it has been created there, so it is never in flight.
        guard let localPath = localURL()?.path.fileProviderStoragePath else {
            return false
        }
        return MEGASdk.shared.uploadTransfers
            .toTransferEntities()
            .contains { transfer in
                guard !transfer.isFinished, let transferPath = transfer.path else {
                    return false
                }
                return transferPath.fileProviderStoragePath == localPath
            }
    }

    var favoriteRank: NSNumber? {
        get {
            fileProviderItemMetadataUseCase.favoriteRank(for: itemIdentifier)
        }

        set {
            fileProviderItemMetadataUseCase.setFavoriteRank(for: itemIdentifier, with: newValue)
        }
    }

    var tagData: Data? {
        get {
            fileProviderItemMetadataUseCase.tagData(for: itemIdentifier)
        }

        set {
            fileProviderItemMetadataUseCase.setTagData(for: itemIdentifier, with: newValue)
        }
    }

    // MARK: - Private
        
    /// Location of this node's local copy inside the File Provider storage, or `nil` for anything but a file.
    private func localURL() -> URL? {
        guard node.isFile, let nodePath = nodeAttributeUseCase.pathFor(node: node) else {
            return nil
        }
        return FileProviderStorage.contentURL(forNodePath: nodePath, in: NSFileProviderManager.default.documentStorageURL)
    }

    private func isFileInCloud() -> Bool {
        guard let itemURL = localURL() else {
            return false
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: itemURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return false
        }
        // A partial file left behind by an interrupted transfer must not count as downloaded: `nil == nil`
        // would otherwise report it as complete and Files would stop offering the download.
        guard let localFingerprint = MEGASdk.shared.fingerprint(forFilePath: itemURL.path),
              let remoteFingerprint = node.fingerprint else {
            return false
        }
        return localFingerprint == remoteFingerprint
    }
}

extension String {
    /// fileproviderd and the SDK spell the same location both as `/private/var/…` and as `/var/…`
    /// (see the comment in `FileProviderExtension.persistentIdentifier(at:)`), so two paths are only
    /// comparable once that alias is removed. `standardizedFileURL` only resolves `.` and `..`.
    var fileProviderStoragePath: String {
        let standardized = URL(fileURLWithPath: self).standardizedFileURL.path
        guard standardized.hasPrefix("/private/") else {
            return standardized
        }
        return String(standardized.dropFirst("/private".count))
    }

    fileprivate func toItemIdentifier() -> String {
        let rootNodeHandle = MEGASdk.shared.rootNode?.handle ?? ~UInt64(0)
        let rootNodeBase64Handle = MEGASdk.base64Handle(forHandle: rootNodeHandle)!
        if self == rootNodeBase64Handle {
            return NSFileProviderItemIdentifier.rootContainer.rawValue
        } else {
            return self
        }
    }
}
