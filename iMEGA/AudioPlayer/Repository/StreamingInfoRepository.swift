import Foundation
import MEGAAppSDKRepo

protocol StreamingInfoRepositoryProtocol: Sendable {
    func serverStart()
    func serverStop()
    func info(fromFolderLinkNode: MEGANode) -> AudioPlayerItem?
    func path(fromNode: MEGANode) -> URL?
    func isLocalHTTPProxyServerRunning() -> Bool
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
    
    func info(fromFolderLinkNode: MEGANode) -> AudioPlayerItem? {
        guard let node = sdk.authorizeNode(fromFolderLinkNode),
              let url = path(fromNode: node),
              let name = node.name else { return nil }
        
        return AudioPlayerItem(name: name, url: url, node: node, hasThumbnail: node.hasThumbnail())
    }
    
    func path(fromNode: MEGANode) -> URL? {
        sdk.httpServerIsLocalOnly() ?
                                sdk.httpServerGetLocalLink(fromNode) :
                                sdk.httpServerGetLocalLink(fromNode)?.updatedURLWithCurrentAddress()
    }
    
    func isLocalHTTPProxyServerRunning() -> Bool {
        (sdk.httpServerIsRunning() != 0)
    }
}
