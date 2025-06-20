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
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        /// Filter nodes to detect changes in the node name. We update the audio player's current node only when its name changes.
        /// This is necessary because if the current node lacks metadata, any change in its name should be reflected in the player's display.
        guard let nodeArray = nodeList?.toNodeArray() else { return }
        guard nodeArray.compactMap({ $0.hasChangedType(.name) }).isNotEmpty else { return }

        _reloadItemPublisher.send(nodeArray.toNodeEntities())
    }
}
