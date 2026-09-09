import Foundation
import MEGASwift

protocol OfflineInfoRepositoryProtocol: Sendable {
    /// Fetches audio tracks from a list of local file paths. Each path is mapped into an `TrackEntity` representing an offline audio track.
    /// - Parameter files: Absolute file paths to map.
    /// - Returns: An array of `TrackEntity` for the given files, or `nil` if `files` is `nil`.
    func fetchTracks(from files: [String]?) -> [TrackEntity]?
    
    /// Resolves the local offline file URL for a given audio node, if available.
    /// - Parameter node: The audio node to look up.
    /// - Returns: A file `URL` if the node has an offline copy; otherwise `nil`.
    func offlineFileURL(for node: MEGANode) -> URL?

    /// Resolves the local offline file URLs for many audio nodes in one read of the offline store.
    /// - Parameter nodes: The audio nodes to look up.
    /// - Returns: The file `URL` for each node that has an offline copy; nodes without one are absent.
    func offlineFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL]

    /// Resolves the copy a node has *saved to Offline*, if it is still on disk
    /// - Parameter node: The audio node to look up.
    /// - Returns: The file `URL` of the saved copy, or `nil` when the node was never saved offline
    ///   or its copy is gone.
    func offlineSavedFileURL(for node: MEGANode) -> URL?

    /// Resolves, in one read of the offline store, the copy each node has *saved to Offline*
    /// - Parameter nodes: The audio nodes to look up.
    /// - Returns: The file `URL` for each node whose saved copy is still on disk.
    func offlineSavedFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL]
    
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
    
    func fetchTracks(from files: [String]?) -> [TrackEntity]? {
        files?.compactMap { TrackEntity(url: URL(fileURLWithPath: $0), node: nil) }
    }
    
    func isNodeAvailableOffline(_ node: MEGANode) -> Bool {
        megaStore.offlineNode(with: node) != nil
    }
    
    func offlineFileURL(for node: MEGANode) -> URL? {
        guard let childQueueContext = megaStore.stack.newBackgroundContext() else { return nil }
        return childQueueContext.performAndWait {
            if let offlineNode = megaStore.offlineNode(with: node, context: childQueueContext) {
                return URL(fileURLWithPath: Helper.pathForOffline().append(pathComponent: offlineNode.localPath))
            } else if let base64Handle = node.base64Handle, let name = node.name {
                let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: base64Handle)
                let tmpFilePath = nodeFolderPath.append(pathComponent: name)
            
                return fileManager.fileExists(atPath: tmpFilePath) ? URL(fileURLWithPath: tmpFilePath) : nil
            } else {
                return nil
            }
        }
    }

    func offlineSavedFileURL(for node: MEGANode) -> URL? {
        offlineSavedFileURLs(for: [node])[node]
    }

    func offlineSavedFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL] {
        let localPaths = megaStore.offlineLocalPaths(for: nodes)

        return nodes.reduce(into: [MEGANode: URL]()) { result, node in
            guard let offlinePath = localPaths[node].map({ Helper.pathForOffline().append(pathComponent: $0) }),
                  fileManager.fileExists(atPath: offlinePath) else { return }
            result[node] = URL(fileURLWithPath: offlinePath)
        }
    }

    func offlineFileURLs(for nodes: [MEGANode]) -> [MEGANode: URL] {
        let localPaths = megaStore.offlineLocalPaths(for: nodes)

        return nodes.reduce(into: [MEGANode: URL]()) { result, node in
            if let offlinePath = localPaths[node].map({ Helper.pathForOffline().append(pathComponent: $0) }),
               fileManager.fileExists(atPath: offlinePath) {
                result[node] = URL(fileURLWithPath: offlinePath)
            } else if let base64Handle = node.base64Handle, let name = node.name {
                let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: base64Handle)
                let tmpFilePath = nodeFolderPath.append(pathComponent: name)

                result[node] = fileManager.fileExists(atPath: tmpFilePath) ? URL(fileURLWithPath: tmpFilePath) : nil
            }
        }
    }
}
