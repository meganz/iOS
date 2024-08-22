@preconcurrency import Combine
import MEGADomain
import MEGASdk

public final class AudioPlayerRepository: NSObject, AudioPlayerRepositoryProtocol {
    private let sdk: MEGASdk
    private let _reloadItemPublisher = PassthroughSubject<[NodeEntity], Never>()
    
    public var reloadItemPublisher: AnyPublisher<[NodeEntity], Never> {
        _reloadItemPublisher.eraseToAnyPublisher()
    }
    
    public static var newRepo: AudioPlayerRepository {
        AudioPlayerRepository(sdk: .sharedSdk)
    }
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func registerMEGADelegate() async {
        sdk.add(self)
    }
    
    public func unregisterMEGADelegate() async {
        sdk.remove(self)
    }
}

extension AudioPlayerRepository: MEGADelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList) {
        _reloadItemPublisher.send(nodeList.toNodeArray().toNodeEntities())
    }
}
