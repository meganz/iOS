import AsyncAlgorithms
import MEGADomain
import MEGARepo
import MEGASwift

protocol DownloadedNodesListening: Sendable {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> { get }
}

final class CloudDriveDownloadedNodesListener: DownloadedNodesListening {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> {
        subListeners.map(\.downloadedNodes)
            .reduce(into: EmptyAsyncSequence<NodeEntity>().eraseToAnyAsyncSequence()) { result, downloadedNodesSequence in
                result = merge(result, downloadedNodesSequence).eraseToAnyAsyncSequence()
            }
    }
    
    private let subListeners: [any DownloadedNodesListening]
    
    init(subListeners: [any DownloadedNodesListening]) {
        self.subListeners = subListeners
    }
}

struct NodesSavedToOfflineListener: DownloadedNodesListening {
    var downloadedNodes: AnyAsyncSequence<NodeEntity> {
        notificationCenter.publisher(for: .nodeSavedToOffline)
            .compactMap {
                $0.object as? NodeEntity
            }
            .values
            .eraseToAnyAsyncSequence()
    }
    
    private let notificationCenter: NotificationCenter
    
    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
    }
}
