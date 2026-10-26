import Foundation
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
    private let serverCoordinator: StreamingServerCoordinator
    /// One per player, so one player stopping cannot take the server from another — two videos can
    /// stream at once, with one in Picture in Picture
    private let serverOwner: String

    public init(
        sdk: MEGASdk,
        serverCoordinator: StreamingServerCoordinator = .shared,
        serverOwner: String = "VideoPlayer-\(UUID().uuidString)"
    ) {
        self.sdk = sdk
        self.serverCoordinator = serverCoordinator
        self.serverOwner = serverOwner
    }

    public func httpServerGetLocalLink(_ node: any PlayableNode) -> URL? {
        guard let megaNode = node as? MEGANode else {
            return nil
        }

        return sdk.httpServerGetLocalLink(megaNode)
    }

    public func httpServerStart() {
        serverCoordinator.acquire(serverOwner, on: sdk)
    }

    public func httpServerStop() {
        serverCoordinator.release(serverOwner)
    }

    public func httpServerSetThrottleBitrate(_ bitrateBps: UInt64) {
        sdk.httpServerSetThrottleBitrate(bitrateBps)
    }
}
