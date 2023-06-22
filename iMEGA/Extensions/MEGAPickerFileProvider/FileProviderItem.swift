import FileProvider
import MEGADomain
import MEGASwift
import UniformTypeIdentifiers

final class FileProviderItem: NSObject, NSFileProviderItem {
    private let node: NodeEntity
    private let nodeAttributeUseCase: any NodeAttributeUseCaseProtocol
    
    init(node: NodeEntity) {
        self.node = node
        self.nodeAttributeUseCase = NodeAttributeUseCase(repo: NodeAttributeRepository.newRepo)
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
    
    var isUploading: Bool {
        let uploadingTransfers = MEGASdk.shared.uploadTransfers.toTransferEntities().filter { !$0.isFinished }
        
        guard !uploadingTransfers.isEmpty else {
            return false
        }
        
        for transfer in uploadingTransfers {
            if let transferPath = transfer.path,
               let nodePath = nodeAttributeUseCase.pathFor(node: node) {
                if transferPath.contains(nodePath) {
                    return true
                }
            }
        }
        
        return false

    }
    
    // MARK: - Private
        
    private func isFileInCloud() -> Bool {
        guard let path = nodeAttributeUseCase.pathFor(node: node) else {
            return false
        }
        let itemURL = NSFileProviderManager.default.documentStorageURL.appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: itemURL.path) else {
            return false
        }
        return MEGASdk.shared.fingerprint(forFilePath: itemURL.path) == node.fingerprint
    }
}

private extension String {
    func toItemIdentifier() -> String {
        let rootNodeHandle = MEGASdk.shared.rootNode?.handle ?? ~UInt64(0)
        let rootNodeBase64Handle = MEGASdk.base64Handle(forHandle: rootNodeHandle)!
        if self == rootNodeBase64Handle {
            return NSFileProviderItemIdentifier.rootContainer.rawValue
        } else {
            return self
        }
    }
}
