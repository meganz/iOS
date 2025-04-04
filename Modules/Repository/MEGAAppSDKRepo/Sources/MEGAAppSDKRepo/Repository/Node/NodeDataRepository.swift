import MEGADomain
import MEGASdk
import MEGASwift

public struct NodeDataRepository: NodeDataRepositoryProtocol {
    public static var newRepo: NodeDataRepository {
        NodeDataRepository(
            sdk: MEGASdk.sharedSdk, sharedFolderSdk: MEGASdk.sharedFolderLinkSdk)
    }
    
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk
    
    init(sdk: MEGASdk, sharedFolderSdk: MEGASdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
    }
    
    public func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return .unknown
        }
        return NodeAccessTypeEntity(shareAccess: sdk.accessLevel(for: node)) ?? .unknown
    }
    
    public func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity {
        await Task.detached {
            nodeAccessLevel(nodeHandle: nodeHandle)
        }.value
    }
    
    public func labelString(label: NodeLabelTypeEntity) -> String {
        let nodeLabel = MEGANodeLabel(nodeLabelTypeEntity: label) ?? .unknown
        return MEGANode.string(for: nodeLabel) ?? "" + "Small"
    }
    
    public func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return (0, 0)
        }
        
        let numberOfFiles = sdk.numberChildFiles(forParent: node)
        let numberOfFolders = sdk.numberChildFolders(forParent: node)
        
        return (numberOfFiles, numberOfFolders)
    }
    
    public func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity? {
        guard let node = node.toMEGANode(in: sdk) else {
            throw FolderInfoErrorEntity.notFound
        }
        
        return try await withAsyncThrowingValue(in: { completion in
            sdk.getFolderInfo(for: node, delegate: RequestDelegate { result in
                switch result {
                case .failure:
                    completion(.failure(FolderInfoErrorEntity.notFound))
                case .success(let request):
                    guard let megaFolderInfo = request.megaFolderInfo else {
                        completion(.failure(FolderInfoErrorEntity.notFound))
                        return
                    }
                    completion(.success(megaFolderInfo.toFolderInfoEntity()))
                }
            })
        })
    }
    
    public func folderLinkInfo(_ folderLink: String) async throws -> FolderLinkInfoEntity? {
        try await withAsyncThrowingValue { completion in
            sdk.getPublicLinkInformation(withFolderLink: folderLink, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.toFolderLinkInfoEntity()))
                case .failure:
                    completion(.failure(FolderInfoErrorEntity.notFound))
                }
            })
        }
    }
    
    public func sizeForNode(handle: HandleEntity) -> UInt64? {
        var megaNode: MEGANode
        if let node = sdk.node(forHandle: handle) {
            megaNode = node
        } else if let node = sharedFolderSdk.node(forHandle: handle) {
            megaNode = node
        } else {
            return nil
        }
        
        if megaNode.isFile() {
            return megaNode.size?.uint64Value
        } else {
            return sdk.size(for: megaNode).uint64Value
        }
    }
    
    public func creationDateForNode(handle: HandleEntity) -> Date? {
        guard let node = sdk.node(forHandle: handle) else {
            return nil
        }
        
        return node.creationTime
    }
    
    public func nodeForHandle(_ handle: HandleEntity) -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    public func nodeForHandle(_ handle: HandleEntity) async -> NodeEntity? {
        await sdk.node(for: handle)?.toNodeEntity()
    }
    
    public func parentForHandle(_ handle: HandleEntity) -> NodeEntity? {
        guard let nodeEntity = nodeForHandle(handle),
              let node = nodeEntity.toMEGANode(in: sdk) else { return nil }
        return sdk.parentNode(for: node)?.toNodeEntity()
    }
}
