import MEGADomain
import MEGASdk

public struct StreamingRepository: StreamingRepositoryProtocol {
    public static var newRepo: StreamingRepository {
        StreamingRepository(
            sdk: .sharedSdk
        )
    }
    
    public var httpServerIsLocalOnly: Bool {
        sdk.httpServerIsLocalOnly()
    }

    public var httpServerIsRunning: Int {
        sdk.httpServerIsRunning()
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func httpServerGetLocalLink(_ node: any PlayableNode) -> URL? {
        guard let megaNode = node as? MEGANode else {
            return nil
        }

        return sdk.httpServerGetLocalLink(megaNode)
    }

    public func httpServerStart(_ localOnly: Bool, port: Int) {
        sdk.httpServerStart(localOnly, port: port)
    }

    public func httpServerStop() {
        sdk.httpServerStop()
    }
}
