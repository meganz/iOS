import MEGADomain
import MEGASdk

public struct AudioStreamingRepository: AudioStreamingRepositoryProtocol {
    public static var newRepo: AudioStreamingRepository {
        AudioStreamingRepository(sdk: .sharedSdk, folderSDK: .sharedFolderLinkSdk)
    }

    /// Streams every track, logged in or not, so audio shares one server with the video player. A
    /// folder-link node is authorized against `folderSDK` first, and its link carries the key and
    /// authorization this SDK's server needs to stream a node outside its own tree.
    private let sdk: MEGASdk
    private let folderSDK: MEGASdk
    private let serverCoordinator: StreamingServerCoordinator

    /// The audio player is a single session, so one owner id covers it
    private static let serverOwner = "AudioPlayer"

    public init(sdk: MEGASdk, folderSDK: MEGASdk, serverCoordinator: StreamingServerCoordinator = .shared) {
        self.sdk = sdk
        self.folderSDK = folderSDK
        self.serverCoordinator = serverCoordinator
    }

    public var isServerRunning: Bool { sdk.httpServerIsRunning() != 0 }

    public func startServer() { serverCoordinator.acquire(Self.serverOwner, on: sdk) }

    public func stopServer() { serverCoordinator.release(Self.serverOwner) }

    public func streamingURL(for node: StreamingNode) -> URL? {
        switch node {
        case .account(let node):
            // Cloud / chat / search nodes live in the account tree and stream without authorization.
            guard let megaNode = resolve(node, in: sdk) else { return nil }
            return localLink(for: megaNode)

        case .folderLink(let node):
            // Authorized against the folder-link tree, then streamed through the account SDK's server.
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

    /// The loopback link the SDK hands back, used as-is
    private func localLink(for node: MEGANode) -> URL? {
        sdk.httpServerGetLocalLink(node)
    }
}
