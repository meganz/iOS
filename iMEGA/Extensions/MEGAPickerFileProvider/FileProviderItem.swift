import FileProvider
import UniformTypeIdentifiers
import MEGADomain

final class FileProviderItem: NSObject, NSFileProviderItem {
    private let node: NodeEntity
    private let nodeAttributeUseCase: NodeAttributeUseCaseProtocol
    
    init(node: NodeEntity) {
        self.node = node
        self.nodeAttributeUseCase = NodeAttributeUseCase(repo: NodeAttributeRepository.newRepo)
    }
    
    var itemIdentifier: NSFileProviderItemIdentifier {
        guard let path = nodeAttributeUseCase.pathFor(node: node) else {
            assertionFailure("Path is needed")
            return NSFileProviderItemIdentifier("")
        }
        
        if path == "/" {
            return NSFileProviderItemIdentifier.rootContainer
        }
        return NSFileProviderItemIdentifier(path)
    }
    
    var parentItemIdentifier: NSFileProviderItemIdentifier {
        if MEGASdk.shared.rootNode?.handle == node.handle {
            return itemIdentifier
        }
        
        guard let parentNode = MEGASdk.shared.node(forHandle: node.parentHandle),
              let parentPath = nodeAttributeUseCase.pathFor(node: parentNode.toNodeEntity()) else {
            assertionFailure("Parent path is needed")
            return NSFileProviderItemIdentifier("")
        }
        
        if parentPath == "/" {
            return NSFileProviderItemIdentifier(NSFileProviderItemIdentifier.rootContainer.rawValue)
        } else {
            return NSFileProviderItemIdentifier(parentPath)
        }
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
        
        let nameUrl = URL(fileURLWithPath: node.name)
        return UTType(filenameExtension: nameUrl.pathExtension) ?? .data
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
