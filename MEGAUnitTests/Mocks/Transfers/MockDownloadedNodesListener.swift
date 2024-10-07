@testable import MEGA
import MEGADomain
import MEGASwift

final class MockDownloadedNodesListener: DownloadedNodesListening {
    private let (stream, continuation) = AsyncStream
        .makeStream(of: NodeEntity.self)
    
    var downloadedNodes: AnyAsyncSequence<NodeEntity> { stream.eraseToAnyAsyncSequence() }
    
    func simulateDownloadedNode(_ node: NodeEntity) {
        continuation.yield(node)
    }
}
