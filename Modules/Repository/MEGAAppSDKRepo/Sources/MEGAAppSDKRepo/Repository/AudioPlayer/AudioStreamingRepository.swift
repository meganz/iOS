import MEGADomain
import MEGASdk

public struct AudioStreamingRepository: AudioStreamingRepositoryProtocol {
    public static var newRepo: AudioStreamingRepository {
        AudioStreamingRepository(sdk: .sharedSdk, folderSDK: .sharedFolderLinkSdk)
    }

    private let sdk: MEGASdk
    private let folderSDK: MEGASdk

    public init(sdk: MEGASdk, folderSDK: MEGASdk) {
        self.sdk = sdk
        self.folderSDK = folderSDK
    }

    private var streamingSDK: MEGASdk {
        MEGASdk.isLoggedIn ? sdk : folderSDK
    }

    public var isServerRunning: Bool { streamingSDK.httpServerIsRunning() != 0 }

    public func startServer() { streamingSDK.httpServerStart(false, port: 4443) }

    public func stopServer() { streamingSDK.httpServerStop() }

    public func streamingURL(for node: StreamingNode) -> URL? {
        switch node {
        case .account(let node):
            // Cloud / chat / search nodes live in the account tree and stream without authorization.
            guard let megaNode = resolve(node, in: sdk) else { return nil }
            return localLink(for: megaNode)

        case .folderLink(let node):
            // Authorized against the folder-link tree, then streamed via the login-state server.
            guard let megaNode = resolve(node, in: folderSDK),
                  let authorized = folderSDK.authorizeNode(megaNode) else { return nil }
            return localLink(for: authorized)

        case .fileLink(let node):
            // A standalone public node already resolved upstream — used directly, no authorization.
            guard let megaNode = node as? MEGANode else { return nil }
            return localLink(for: megaNode)
        }
    }

    // MARK: - Private

    /// Returns the underlying `MEGANode`: the object directly when one was carried
    /// through, otherwise a tree lookup by handle in the given SDK.
    private func resolve(_ node: any PlayableNode, in sdk: MEGASdk) -> MEGANode? {
        (node as? MEGANode) ?? sdk.node(forHandle: node.handle)
    }

    private func localLink(for node: MEGANode) -> URL? {
        let server = streamingSDK
        guard let link = server.httpServerGetLocalLink(node) else { return nil }
        return server.httpServerIsLocalOnly() ? link : link.updatedURLWithCurrentAddress()
    }
}
