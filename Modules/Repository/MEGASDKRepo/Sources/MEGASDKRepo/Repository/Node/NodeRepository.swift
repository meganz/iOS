import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeRepository: NodeRepositoryProtocol {
    public static var newRepo: NodeRepository {
        let sdk = MEGASdk.sharedSdk
        return NodeRepository(sdk: sdk,
                              sharedFolderSdk: MEGASdk.sharedFolderLinkSdk,
                              nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk))
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        nodeUpdatesProvider.nodeUpdates
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    private let nodeUpdatesProvider: any NodeUpdatesProviderProtocol
    
    public init(sdk: MEGASdk,
                sharedFolderSdk: MEGASdk,
                nodeUpdatesProvider: some NodeUpdatesProviderProtocol) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
        self.nodeUpdatesProvider = nodeUpdatesProvider
    }
    
    // MARK: - Node
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        if let node = sdk.node(forHandle: handle) {
            return node.toNodeEntity()
        } else if let node = sharedFolderSdk.node(forHandle: handle) {
            return node.toNodeEntity()
        }
        
        return nil
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            sdk.publicNode(forMegaFileLink: fileLink.linkURL.absoluteString, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = request.publicNode else {
                        continuation.resume(throwing: NodeErrorEntity.nodeNotFound)
                        return
                    }
                    continuation.resume(returning: node.toNodeEntity())
                case .failure:
                    continuation.resume(throwing: NodeErrorEntity.nodeNotFound)
                }
            })
        }
    }
    
    public func childNodeNamed(name: String, in parentHandle: HandleEntity) -> NodeEntity? {
        guard let parent = sdk.node(forHandle: parentHandle), let node = sdk.childNode(forParent: parent, name: name) else {
            return nil
        }
        
        return node.toNodeEntity()
    }
    
    public func childNode(parent node: NodeEntity,
                          name: String,
                          type: NodeTypeEntity
    ) async -> NodeEntity? {
        guard let parent = node.toMEGANode(in: sdk) else {
            return nil
        }
        return sdk.childNode(
            forParent: parent,
            name: name,
            type: type.toMEGANodeType()
        )?.toNodeEntity()
    }
    
    public func rubbishNode() -> NodeEntity? {
        sdk.rubbishNode?.toNodeEntity()
    }
    
    public func rootNode() -> NodeEntity? {
        sdk.rootNode?.toNodeEntity()
    }
    
    public func parents(of node: NodeEntity) async -> [NodeEntity] {
        let parentTreeTask = Task.detached { () -> [NodeEntity] in
            guard let node = node.toMEGANode(in: sdk) else { return [] }
            var parentTreeArray = [NodeEntity]()
            
            if sdk.accessLevel(for: node) == .accessOwner {
                var rootHandle: HandleEntity?
                if sdk.nodePath(for: node)?.hasPrefix("//bin") == true {
                    rootHandle = rubbishNode()?.parentHandle
                } else {
                    rootHandle = rootNode()?.handle
                }
                
                var tempHandle = node.parentHandle
                if node.isFolder(), let nodeEntity = nodeForHandle(node.handle) {
                    parentTreeArray.append(nodeEntity)
                }
                repeat {
                    if let tempNode = nodeForHandle(tempHandle), tempHandle != rootHandle {
                        parentTreeArray.insert(tempNode, at: 0)
                        tempHandle = tempNode.parentHandle
                    } else {
                        break
                    }
                } while tempHandle != rootHandle
            } else {
                var tempNode = sdk.node(forHandle: node.parentHandle)?.toNodeEntity()
                while tempNode != nil {
                    if let tempNode, tempNode.handle != sdk.rootNode?.handle { parentTreeArray.insert(tempNode, at: 0) }
                    tempNode = sdk.node(forHandle: tempNode!.parentHandle)?.toNodeEntity()
                }
            }
            
            return parentTreeArray
        }
        return await parentTreeTask.value
    }
    
    public func children(of node: NodeEntity) -> NodeListEntity? {
        guard let node = node.toMEGANode(in: sdk) else { return nil }
        return sdk.children(forParent: node).toNodeListEntity()
    }
    
    public func asyncChildren(of node: NodeEntity, sortOrder: SortOrderEntity) async -> NodeListEntity? {
        guard let node = node.toMEGANode(in: sdk) else { return nil }
        return sdk.children(forParent: node, order: sortOrder.toMEGASortOrderType().rawValue).toNodeListEntity()
    }
    
    public func childrenNames(of node: NodeEntity) -> [String]? {
        guard let node = sdk.node(forHandle: node.handle) else { return nil }
        return sdk
            .children(forParent: node)
            .toNodeArray()
            .compactMap(\.name)
    }

    public func isInRubbishBin(node: NodeEntity) -> Bool {
        guard let node = node.toMEGANode(in: sdk) else { return false }
        return sdk.isNode(inRubbish: node)
    }

    public func createFolder(with name: String, in parent: NodeEntity) async throws -> NodeEntity {
        guard let node = parent.toMEGANode(in: sdk) else {
            throw NodeCreationErrorEntity.nodeNotFound
        }

        guard sdk.childNode(forParent: node, name: name, type: .folder) == nil else {
            throw NodeCreationErrorEntity.nodeAlreadyExists
        }

        return try await withCheckedThrowingContinuation { continuation in
            sdk.createFolder(withName: name, parent: node, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    if let newFolderNode = sdk.node(forHandle: request.nodeHandle) {
                        continuation.resume(returning: newFolderNode.toNodeEntity())
                    } else {
                        continuation.resume(throwing: NodeCreationErrorEntity.nodeCreatedButCannotBeSearched)
                    }
                case .failure:
                    continuation.resume(throwing: NodeCreationErrorEntity.nodeCreationFailed)
                }
            })
        }
    }
    
    public func isInheritingSensitivity(node: NodeEntity) async throws -> Bool {
        guard let node = sdk.node(forHandle: node.parentHandle) else {
            throw NodeErrorEntity.nodeNotFound
        }
        return sdk.isNodeInheritingSensitivity(node)
    }
    
    public func isInheritingSensitivity(node: NodeEntity) throws -> Bool {
        guard let node = sdk.node(forHandle: node.parentHandle) else {
            throw NodeErrorEntity.nodeNotFound
        }
        return sdk.isNodeInheritingSensitivity(node)
    }
}
