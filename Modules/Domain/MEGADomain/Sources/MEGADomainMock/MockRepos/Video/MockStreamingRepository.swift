import Foundation
import MEGADomain

public final class MockStreamingRepository: StreamingRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockStreamingRepository {
        MockStreamingRepository()
    }

    public var httpServerIsLocalOnly: Bool
    public var httpServerIsRunning: Int
    public var localLink: URL?

    public private(set) var httpServerStartCallCount = 0
    public private(set) var httpServerStopCallCount = 0
    public private(set) var throttleBitrates: [UInt64] = []

    public init(
        httpServerIsLocalOnly: Bool = false,
        httpServerIsRunning: Int = 0,
        localLink: URL? = URL(string: "https://mega.test/streaming")
    ) {
        self.httpServerIsLocalOnly = httpServerIsLocalOnly
        self.httpServerIsRunning = httpServerIsRunning
        self.localLink = localLink
    }

    public func httpServerGetLocalLink(_ node: any PlayableNode) -> URL? {
        localLink
    }

    public func httpServerStart(_ localOnly: Bool, port: Int) {
        httpServerStartCallCount += 1
    }

    public func httpServerStop() {
        httpServerStopCallCount += 1
    }

    public func httpServerSetThrottleBitrate(_ bitrateBps: UInt64) {
        throttleBitrates.append(bitrateBps)
    }
}
