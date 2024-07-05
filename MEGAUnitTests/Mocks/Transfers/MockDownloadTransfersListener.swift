@testable import MEGA
import MEGADomain
import MEGASwift

final class MockDownloadTransfersListener: DownloadTransfersListening {
    private let (stream, continuation) = AsyncStream
        .makeStream(of: NodeEntity.self, bufferingPolicy: .bufferingNewest(1))
    
    var downloadedNodes: AnyAsyncSequence<NodeEntity> { stream.eraseToAnyAsyncSequence() }
    
    func simulateDownloadedNode(_ node: NodeEntity) {
        continuation.yield(node)
    }
}
