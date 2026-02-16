import MEGADomain
import MEGASwift

public protocol DownloadedNodesListening: Sendable {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> { get }
}
