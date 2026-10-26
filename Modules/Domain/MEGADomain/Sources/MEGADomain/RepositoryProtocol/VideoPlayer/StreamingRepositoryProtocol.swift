import Foundation

public protocol StreamingRepositoryProtocol: RepositoryProtocol, Sendable {
    var httpServerIsLocalOnly: Bool { get }
    var httpServerIsRunning: Int { get }

    func httpServerGetLocalLink(_ node: any PlayableNode) -> URL?
    /// Holds the streaming server for this player, starting it if it is not running. Takes no settings:
    /// the server is shared by every player, so it has one configuration for all of them.
    func httpServerStart()
    func httpServerStop()

    /// Caps the streaming server's download speed, in bits per second. `0` removes the cap.
    func httpServerSetThrottleBitrate(_ bitrateBps: UInt64)
}
