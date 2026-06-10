import MEGADomain
import MEGASdk

public struct AudioStreamingRepository: StreamingRepositoryProtocol {
    public static var newRepo: Self { Self(sdk: .sharedSdk) }
    public static var folderLinkRepo: Self { Self(sdk: .sharedFolderLinkSdk) }

    public var httpServerIsLocalOnly: Bool { sdk.httpServerIsLocalOnly() }
    public var httpServerIsRunning: Int { sdk.httpServerIsRunning() }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) { self.sdk = sdk }

    public func httpServerGetLocalLink(_ node: any PlayableNode) -> URL? {
        guard let megaNode = sdk.node(forHandle: node.handle), let authorized = sdk.authorizeNode(megaNode) else {
            return nil
        }
        return sdk.httpServerGetLocalLink(authorized)
    }

    public func httpServerStart(_ localOnly: Bool, port: Int) {
        sdk.httpServerStart(localOnly, port: port)
    }

    public func httpServerStop() {
        sdk.httpServerStop()
    }
}
