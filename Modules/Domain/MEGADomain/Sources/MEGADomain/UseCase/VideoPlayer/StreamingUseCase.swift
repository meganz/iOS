import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

public protocol StreamingUseCaseProtocol: Sendable {
    var isStreaming: Bool { get }

    func startStreaming()
    func stopStreaming()
    func streamingLink(for node: any PlayableNode) -> URL?

    /// Throttles the streaming server to the bandwidth the given media actually needs.
    ///
    /// Only high-bitrate media is throttled: below the threshold the cap is removed instead, since
    /// unthrottled streaming of ordinary media is not what starves playback.
    ///
    /// - Parameters:
    ///   - totalBitrate: Combined estimated data rate of all media tracks, in bits per second.
    ///   - playbackRate: Current playback rate; values below `1.0` are clamped to `1.0`.
    /// - Returns: `true` when a throttle was installed, `false` when the cap was removed.
    @discardableResult
    func updateThrottleBitrate(totalBitrate: Float, playbackRate: Float) -> Bool

    /// Removes any streaming throttle, so it doesn't carry over to the next playback.
    func resetThrottleBitrate()
}

public struct StreamingUseCase: StreamingUseCaseProtocol {
    /// Media below this combined bitrate streams fine unthrottled, so no cap is installed for it.
    private static let highBitrateThreshold: Float = 15_000_000

    public var isStreaming: Bool {
        repository.httpServerIsRunning != 0
    }

    private let repository: any StreamingRepositoryProtocol

    public init(repository: some StreamingRepositoryProtocol) {
        self.repository = repository
    }

    public func streamingLink(for node: any PlayableNode) -> URL? {
        repository.httpServerGetLocalLink(node)
    }

    public func startStreaming() {
        repository.httpServerStart(false, port: 4443)
    }

    public func stopStreaming() {
        repository.httpServerStop()
    }

    @discardableResult
    public func updateThrottleBitrate(totalBitrate: Float, playbackRate: Float) -> Bool {
        guard totalBitrate.isFinite, totalBitrate > Self.highBitrateThreshold else {
            resetThrottleBitrate()
            return false
        }

        let rate = max(playbackRate.isFinite ? playbackRate : 1.0, 1.0)
        let scaled = totalBitrate * rate * 3
        guard scaled.isFinite, scaled >= 0, scaled < Float(UInt64.max) else {
            return false
        }

        repository.httpServerSetThrottleBitrate(UInt64(scaled))
        return true
    }

    public func resetThrottleBitrate() {
        repository.httpServerSetThrottleBitrate(0)
    }
}

extension URL {
    /// Replaces the loopback address in a URL (`[::1]`) with the device’s local IP address if available.
    ///
    /// This is necessary for enabling local HTTP streaming from the device to other devices on the same Wi-Fi network.
    /// The default link returned by the SDK contains a loopback address (`[::1]`), which refers only to the local device.
    /// By replacing it with the actual IP address on the local network (e.g. `192.168.1.x`), we make the HTTP server
    /// accessible from external clients such as Chromecast, AirPlay, or other peers.
    ///
    /// - Returns: A new `URL` instance with the loopback address replaced, or `self` if the local IP address is not available.
    public func updatedURLWithCurrentAddress() -> URL {
        let loopbackAddress = "[::1]"
        guard let localIPAddress = localWiFiIPAddress() else {
            return self
        }

        let updatedString = self.absoluteString.replacingOccurrences(of: loopbackAddress, with: localIPAddress)
        return URL(string: updatedString) ?? self
    }

    /// Retrieves the device's IPv4 address for the Wi-Fi interface (typically `en0`).
    ///
    /// - Returns: The local IP address as a `String`, or `nil` if unavailable.
    private func localWiFiIPAddress() -> String? {
        var address: String?
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfacePointer) == 0, let firstInterface = interfacePointer else {
            return nil
        }

        defer { freeifaddrs(interfacePointer) }

        for pointer in sequence(first: firstInterface, next: { $0.pointee.ifa_next }) {
            let interface = pointer.pointee
            let interfaceName = String(cString: interface.ifa_name)
            let addressFamily = interface.ifa_addr.pointee.sa_family

            guard addressFamily == UInt8(AF_INET), interfaceName == "en0" else { continue}

            var socketAddress = interface.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            let result = getnameinfo(
                &socketAddress,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            if result == 0 {
                address = String(decoding: hostname.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
                break
            }
        }

        return address
    }
}
