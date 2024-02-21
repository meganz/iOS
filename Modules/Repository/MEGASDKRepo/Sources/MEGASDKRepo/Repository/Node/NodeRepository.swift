import MEGADomain
import MEGASdk

public struct NodeRepository: NodeRepositoryProtocol {
    
    public static var newRepo: NodeRepository {
        NodeRepository(sdk: MEGASdk.sharedSdk, sharedFolderSdk: MEGASdk.sharedFolderLinkSdk)
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    
    public init(sdk: MEGASdk, sharedFolderSdk: MEGASdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
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
    
    public func nodeFor(fileLink: FileLinkEntity, completion: @escaping (Result<NodeEntity, NodeErrorEntity>) -> Void) {
        sdk.publicNode(forMegaFileLink: fileLink.linkURL.absoluteString, delegate: RequestDelegate { (result) in
            switch result {
            case .success(let request):
                guard let node = request.publicNode else {
                    completion(.failure(.nodeNotFound))
                    return
                }
                completion(.success(node.toNodeEntity()))
            case .failure:
                completion(.failure(.nodeNotFound))
            }
        })
    }
    
    public func nodeFor(fileLink: FileLinkEntity) async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            nodeFor(fileLink: fileLink) { result in
                switch result {
                case .success(let node):
                    continuation.resume(returning: node)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
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
                          type: NodeTypeEntity) async -> NodeEntity? {
        guard let parent = node.toMEGANode(in: sdk) else {
            return nil
        }
        return sdk.childNode(forParent: parent,
                             name: name,
                             type: type.rawValue)?.toNodeEntity()
    }
    
    public func images(for parentNode: NodeEntity) -> [NodeEntity] {
        guard let parent = parentNode.toMEGANode(in: sdk) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    public func images(for parentHandle: HandleEntity) -> [NodeEntity] {
        guard let parent = sdk.node(forHandle: parentHandle) else { return [] }
        
        return images(forParentNode: parent)
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
    
    public func asyncChildren(of node: NodeEntity) async -> NodeListEntity? {
        guard let node = node.toMEGANode(in: sdk) else { return nil }
        return sdk.children(forParent: node).toNodeListEntity()
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

    // MARK: - Private
    private func images(forParentNode node: MEGANode) -> [NodeEntity] {
        let nodeList = sdk.children(forParent: node)
        let mediaNodes = nodeList.toNodeArray().filter { $0.name?.fileExtensionGroup.isMultiMedia == true }
        let imageNodes = mediaNodes.filter { $0.name?.fileExtensionGroup.isImage == true }
        
        return imageNodes.toNodeEntities()
    }
}
