import MEGADomain
import MEGASdk
import MEGASwift

public struct ShareCollectionRepository: ShareCollectionRepositoryProtocol {
    public static var newRepo: ShareCollectionRepository {
        ShareCollectionRepository(sdk: MEGASdk.sharedSdk,
                             publicAlbumNodeProvider: PublicAlbumNodeProvider.shared)
    }
    
    private let sdk: MEGASdk
    private let publicAlbumNodeProvider: any PublicAlbumNodeProviderProtocol
    
    public init(sdk: MEGASdk,
                publicAlbumNodeProvider: some PublicAlbumNodeProviderProtocol) {
        self.sdk = sdk
        self.publicAlbumNodeProvider = publicAlbumNodeProvider
    }
    
    public func shareCollectionLink(_ album: AlbumEntity) async throws -> String? {
        if album.isLinkShared {
            return sdk.publicLinkForExportedSet(bySid: album.id)
        }
        return try await withAsyncThrowingValue(in: { completion in
            sdk.exportSet(album.id, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.link))
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(ShareCollectionErrorEntity.buisinessPastDue))
                    } else {
                        completion(.failure(GenericErrorEntity()))
                    }
                }
            })
        })
    }
    
    public func removeSharedLink(forCollectionId id: HandleEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.disableExportSet(id, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    if error.type == .apiEBusinessPastDue {
                        completion(.failure(ShareCollectionErrorEntity.buisinessPastDue))
                    } else {
                        completion(.failure(GenericErrorEntity()))
                    }
                }
            })
        }
    }
    
    public func publicCollectionContents(forLink link: String) async throws -> SharedCollectionEntity {
        await publicAlbumNodeProvider.clearCache()
        
        return try await withAsyncThrowingValue { completion in
            sdk.stopPublicSetPreview()
            
            sdk.fetchPublicSet(link, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let set = request.set else {
                        completion(.failure(GenericErrorEntity()))
                        return
                    }
                    let sharedCollectionEntity = SharedCollectionEntity(set: set.toSetEntity(),
                                                                            setElements: request.elementsInSet?.toSetElementsEntities() ?? [])
                    completion(.success(sharedCollectionEntity))
                case .failure(let error):
                    let errorEntity: Error
                    switch error.type {
                    case .apiENoent:
                        errorEntity = SharedCollectionErrorEntity.resourceNotFound
                    case .apiEInternal:
                        errorEntity = SharedCollectionErrorEntity.couldNotBeReadOrDecrypted
                    case .apiEArgs:
                        errorEntity = SharedCollectionErrorEntity.malformed
                    case .apiEAccess:
                        errorEntity = SharedCollectionErrorEntity.permissionError
                    default:
                        errorEntity = GenericErrorEntity()
                    }
                    completion(.failure(errorEntity))
                }
            })
        }
    }
    
    public func stopCollectionLinkPreview() {
        sdk.stopPublicSetPreview()
    }
    
    public func publicNode(_ collection: SetElementEntity) async throws -> NodeEntity? {
        try await publicAlbumNodeProvider.publicPhotoNode(for: collection)?.toNodeEntity()
    }
    
    public func copyPublicNodes(toFolder folder: NodeEntity, nodes: [NodeEntity]) async throws -> [NodeEntity] {
        guard nodes.isNotEmpty else { return [] }
        guard let collectionFolder = sdk.node(forHandle: folder.handle) else {
            throw NodeErrorEntity.nodeNotFound
        }
        
        let collectionNodes = await publicCollectionNodes(nodes)
        guard collectionNodes.isNotEmpty, !Task.isCancelled else {
            return []
        }
        
        return try await withThrowingTaskGroup(of: NodeEntity.self, body: { group in
            collectionNodes.forEach { collectionNode in
                group.addTask {
                    return try await copyNodeToFolder(collectionFolder, node: collectionNode)
                }
            }
            return try await group.reduce(into: [NodeEntity](), {
                $0.append($1)
            })
        })
    }
    
    private func copyNodeToFolder(_ folder: MEGANode, node: MEGANode) async throws -> NodeEntity {
        try await withAsyncThrowingValue { completion in
            sdk.copy(node, newParent: folder, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let node = sdk.node(forHandle: request.nodeHandle)?.toNodeEntity() else {
                        completion(.failure(NodeErrorEntity.nodeNotFound))
                        return
                    }
                    completion(.success(node))
                case .failure:
                    completion(.failure(CopyOrMoveErrorEntity.nodeCopyFailed))
                }
            })
        }
    }
    
    private func publicCollectionNodes(_ nodes: [NodeEntity]) async -> [MEGANode] {
        await withTaskGroup(of: MEGANode?.self, body: { group in
            nodes.forEach { node in
                group.addTask {
                    await publicAlbumNodeProvider.node(for: node.handle)
                }
            }
            return await group.reduce(into: [MEGANode](), {
                if let node = $1 { $0.append(node) }
            })
        })
    }
}
