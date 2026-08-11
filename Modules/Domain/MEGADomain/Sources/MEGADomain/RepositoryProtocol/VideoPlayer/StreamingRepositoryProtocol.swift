import Foundation

public protocol StreamingRepositoryProtocol: RepositoryProtocol, Sendable {
    var httpServerIsLocalOnly: Bool { get }
    var httpServerIsRunning: Int { get }

    func httpServerGetLocalLink(_ node: any PlayableNode) -> URL?
    func httpServerStart(_ localOnly: Bool, port: Int)
    func httpServerStop()

    /// Caps the streaming server's download speed, in bits per second. `0` removes the cap.
    func httpServerSetThrottleBitrate(_ bitrateBps: UInt64)
}
