import Foundation
import MEGASwift

protocol OfflineInfoRepositoryProtocol: Sendable {
    /// Fetches audio tracks from a list of local file paths. Each path is mapped into an `AudioPlayerItem` representing an offline audio track.
    /// - Parameter files: Absolute file paths to map.
    /// - Returns: An array of `AudioPlayerItem` for the given files, or `nil` if `files` is `nil`.
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]?
    
    /// Resolves the local offline file URL for a given audio node, if available.
    /// - Parameter node: The audio node to look up.
    /// - Returns: A file `URL` if the node has an offline copy; otherwise `nil`.
    func offlineFileURL(for node: MEGANode) -> URL?
    
    /// Determines whether a given audio node is available offline.
    /// - Parameter node: The audio node to check.
    /// - Returns: `true` if the audio node exists in the offline store; otherwise `false`.
    func isNodeAvailableOffline(_ node: MEGANode) -> Bool
}

final class OfflineInfoRepository: OfflineInfoRepositoryProtocol {
    private let megaStore: MEGAStore
    private let fileManager: FileManager
    
    init(megaStore: MEGAStore = MEGAStore.shareInstance(), fileManager: FileManager = FileManager.default) {
        self.megaStore = megaStore
        self.fileManager = fileManager
    }
    
    func fetchTracks(from files: [String]?) -> [AudioPlayerItem]? {
        files?.compactMap { AudioPlayerItem(name: $0.lastPathComponent, url: URL(fileURLWithPath: $0), node: nil) }
    }
    
    func isNodeAvailableOffline(_ node: MEGANode) -> Bool {
        megaStore.offlineNode(with: node) != nil
    }
    
    func offlineFileURL(for node: MEGANode) -> URL? {
        guard let childQueueContext = megaStore.stack.newBackgroundContext() else { return nil }
        var url: URL?
        childQueueContext.performAndWait {
            if let offlineNode = megaStore.offlineNode(with: node, context: childQueueContext) {
                url = URL(fileURLWithPath: Helper.pathForOffline().append(pathComponent: offlineNode.localPath))
            } else if let base64Handle = node.base64Handle, let name = node.name {
                let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: base64Handle)
                let tmpFilePath = nodeFolderPath.append(pathComponent: name)
            
                url = fileManager.fileExists(atPath: tmpFilePath) ? URL(fileURLWithPath: tmpFilePath) : nil
            }
        }
        return url
    }
}
