import Foundation
import MEGASwift

protocol OfflineInfoRepositoryProtocol: Sendable {
    func info(fromFiles: [String]?) -> [AudioPlayerItem]?
    func localPath(fromNode: MEGANode) -> URL?
    func isOffline(node: MEGANode) -> Bool
}

final class OfflineInfoRepository: OfflineInfoRepositoryProtocol {
    
    private let megaStore: MEGAStore
    private let fileManager: FileManager
    
    init(megaStore: MEGAStore = MEGAStore.shareInstance(), fileManager: FileManager = FileManager.default) {
        self.megaStore = megaStore
        self.fileManager = fileManager
    }
    
    func info(fromFiles: [String]?) -> [AudioPlayerItem]? {
        fromFiles?.compactMap { AudioPlayerItem(name: $0.lastPathComponent, url: URL(fileURLWithPath: $0), node: nil) }
    }
    
    func isOffline(node: MEGANode) -> Bool {
        megaStore.offlineNode(with: node) != nil
    }
    
    func localPath(fromNode: MEGANode) -> URL? {
        guard let childQueueContext = megaStore.stack.newBackgroundContext() else { return nil }
        var url: URL?
        childQueueContext.performAndWait {
            if let offlineNode = megaStore.offlineNode(with: fromNode, context: childQueueContext) {
                url = URL(fileURLWithPath: Helper.pathForOffline().append(pathComponent: offlineNode.localPath))
            } else if let base64Handle = fromNode.base64Handle, let name = fromNode.name {
                let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: base64Handle)
                let tmpFilePath = nodeFolderPath.append(pathComponent: name)
            
                url = fileManager.fileExists(atPath: tmpFilePath) ? URL(fileURLWithPath: tmpFilePath) : nil
            }
        }
        return url
    }
}
