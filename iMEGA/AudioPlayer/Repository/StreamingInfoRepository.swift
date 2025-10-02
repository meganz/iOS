import Foundation
import MEGAAppSDKRepo

protocol StreamingInfoRepositoryProtocol: Sendable {
    /// Starts the local HTTP streaming server. Once started, audio nodes can be streamed through locally generated URLs.
    func serverStart()
    
    /// Stops the local HTTP streaming server.
    func serverStop()
    
    /// Converts a node into an `AudioPlayerItem` suitable for playback through the streaming server. The node is authorized for the current SDK context before creating the item.
    /// - Parameter node: The `MEGANode` to map into an audio track.
    /// - Returns: An `AudioPlayerItem` if the node is valid and streamable; otherwise `nil`.
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem?
    
    /// Resolves the streaming URL for a given node.
    /// - Parameter node: The `MEGANode` to resolve.
    /// - Returns: A local HTTP `URL` if available; otherwise `nil`.
    func streamingURL(for node: MEGANode) -> URL?
    
    /// Indicates whether the local HTTP streaming server is currently running.
    /// - Returns: `true` if the server is running; otherwise `false`.
    func isLocalHTTPServerRunning() -> Bool
}

final class StreamingInfoRepository: StreamingInfoRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk = MEGASdk.isLoggedIn ? MEGASdk.sharedSdk : MEGASdk.sharedFolderLinkSdk) {
        self.sdk = sdk
    }
    
    func serverStart() {
        sdk.httpServerStart(false, port: 4443)
    }
    
    func serverStop() {
        sdk.httpServerStop()
    }
    
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem? {
        guard let node = sdk.authorizeNode(node),
              let url = streamingURL(for: node),
              let name = node.name else { return nil }
        
        return AudioPlayerItem(name: name, url: url, node: node, hasThumbnail: node.hasThumbnail())
    }
    
    func streamingURL(for node: MEGANode) -> URL? {
        sdk.httpServerIsLocalOnly() ?
                                sdk.httpServerGetLocalLink(node) :
                                sdk.httpServerGetLocalLink(node)?.updatedURLWithCurrentAddress()
    }
    
    func isLocalHTTPServerRunning() -> Bool {
        (sdk.httpServerIsRunning() != 0)
    }
}
