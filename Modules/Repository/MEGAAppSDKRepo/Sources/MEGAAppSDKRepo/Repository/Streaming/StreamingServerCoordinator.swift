import Foundation
import MEGASdk

/// The SDK runs one local HTTP streaming server per `MEGASdk`, shared by every player that streams
/// through it. Each player holds the server under its own owner id: it starts for the first owner and
/// stops only once the last one lets go, so a player closing cannot take the server away from another.
public final class StreamingServerCoordinator: @unchecked Sendable {
    public static let shared = StreamingServerCoordinator()

    /// The one configuration of the server: on every network interface, so AirPlay can reach it through
    /// the device's Wi-Fi address, on the port the app has always used
    private static let localOnly = false
    private static let port = 4443

    private let lock = NSLock()
    /// The SDK whose server each owner holds
    private var holders: [String: MEGASdk] = [:]

    public init() {}

    /// Holds the server for `owner`, starting it if it is not running. A running server is never started
    /// again: the SDK answers that by revoking every link the server has handed out. Holding it again
    /// under the same owner changes nothing. An owner holds the server of one SDK only, the one its
    /// player streams through.
    public func acquire(_ owner: String, on sdk: MEGASdk) {
        lock.withLock {
            assert(
                holders[owner].map { $0 === sdk } ?? true,
                "[StreamingServerCoordinator] \(owner) holds another SDK's server, which would never be released"
            )
            holders[owner] = sdk
            guard sdk.httpServerIsRunning() == 0 else { return }
            sdk.httpServerStart(Self.localOnly, port: Self.port)
        }
    }

    /// Lets go of the server `owner` holds, stopping it if no other owner holds it. Releasing an owner
    /// that holds nothing does nothing.
    public func release(_ owner: String) {
        lock.withLock {
            guard let sdk = holders.removeValue(forKey: owner),
                  !holders.values.contains(where: { $0 === sdk }) else { return }
            sdk.httpServerStop()
        }
    }
}
