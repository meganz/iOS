import Foundation
import MEGAAppSDKRepo

public struct TrackEntity: Sendable, Equatable {
    public let url: URL
    public let node: MEGANode?

    public init(url: URL, node: MEGANode?) {
        self.url = url
        self.node = node
    }
}
