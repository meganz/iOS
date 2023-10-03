import Combine
import MEGADomain
import MEGASdk

protocol AudioPlayerRepositoryProtocol: RepositoryProtocol {
    var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> { get }
    
    func registerMEGADelegate() async
    func unregisterMEGADelegate() async
}

final class AudioPlayerRepository: NSObject, AudioPlayerRepositoryProtocol {
    private let sdk: MEGASdk
    private let _reloadItemPublisher = PassthroughSubject<[NodeEntity], Never>()
    
    var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> {
        _reloadItemPublisher.eraseToAnyPublisher()
    }
    
    static var newRepo: AudioPlayerRepository {
        AudioPlayerRepository(sdk: .shared)
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func registerMEGADelegate() async {
        sdk.add(self)
    }
    
    func unregisterMEGADelegate() async {
        sdk.remove(self)
    }
}

extension AudioPlayerRepository: MEGADelegate {
    
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList) {
        _reloadItemPublisher.send(nodeList.toNodeArray().toNodeEntities())
    }
}
