@testable import MEGA
import MEGADomain
import MEGASwift

final class MockDownloadedNodesListener: DownloadedNodesListening {
    
    let downloadedNodes: AnyAsyncSequence<NodeEntity>
    
    init(downloadedNodes: AnyAsyncSequence<NodeEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.downloadedNodes = downloadedNodes
    }
}
