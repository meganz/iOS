@preconcurrency import Combine
import MEGADomain
import MEGASdk

final public class AlbumContentsUpdateNotifierRepository: NSObject, AlbumContentsUpdateNotifierRepositoryProtocol {
    public static var newRepo = AlbumContentsUpdateNotifierRepository(sdk: MEGASdk.sharedSdk)
    
    private let albumReloadSourcePublisher = PassthroughSubject<Void, Never>()
    private let sdk: MEGASdk
    
    public var albumReloadPublisher: AnyPublisher<Void, Never> {
        albumReloadSourcePublisher.eraseToAnyPublisher()
    }
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    private func shouldAlbumReload(_ nodes: [NodeEntity]) -> Bool {
        let rubbishNodeHandle = sdk.rubbishNode?.handle
        
        return nodes.contains { node in
            guard !(node.isFolder && node.changeTypes.contains(.sensitive)) else {
                return true
            }
            guard node.fileExtensionGroup.isVisualMedia else { return false }
            
            return [node.changeTypes.intersection([.new, .attributes, .parent,
                                                   .publicLink, .sensitive]).isNotEmpty,
                    node.parentHandle == rubbishNodeHandle]
                .contains { $0 }
        }
    }
}

extension AlbumContentsUpdateNotifierRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let updatedNodes = nodeList?.toNodeEntities(),
        shouldAlbumReload(updatedNodes) else { return }
        albumReloadSourcePublisher.send()
    }
}
