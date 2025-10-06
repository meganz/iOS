import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

public protocol StreamingUseCaseProtocol: Sendable {
    var isStreaming: Bool { get }

    func startStreaming()
    func stopStreaming()
    func streamingLink(for node: any PlayableNode) -> URL?
}

public struct StreamingUseCase: StreamingUseCaseProtocol {
    public var isStreaming: Bool {
        repository.httpServerIsRunning != 0
    }

    private let repository: any StreamingRepositoryProtocol

    public init(repository: some StreamingRepositoryProtocol) {
        self.repository = repository
    }

    public func streamingLink(for node: any PlayableNode) -> URL? {
        if repository.httpServerIsLocalOnly {
            return repository.httpServerGetLocalLink(node)
        } else {
            return repository.httpServerGetLocalLink(node)?.updatedURLWithCurrentAddress()
        }
    }

    public func startStreaming() {
        repository.httpServerStart(false, port: 4443)
    }

    public func stopStreaming() {
        repository.httpServerStop()
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
    func updatedURLWithCurrentAddress() -> URL {
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
