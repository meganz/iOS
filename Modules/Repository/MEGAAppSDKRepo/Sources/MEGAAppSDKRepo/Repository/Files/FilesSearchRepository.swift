import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public final class FilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: FilesSearchRepository {
        FilesSearchRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - FilesSearchRepositoryProtocol
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        MEGAUpdateHandlerManager.shared.nodeUpdates
    }
    
    public var folderLinkNodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        MEGAUpdateHandlerManager.sharedFolderLink.nodeUpdates
    }
    
    public func search(filter: SearchFilterEntity, page: SearchPageEntity) async throws -> [NodeEntity] {
        let nodeList: NodeListEntity = try await search(with: filter, page: page)
        return nodeList.toNodeEntities()
    }
    
    public func search(filter: SearchFilterEntity) async throws -> [NodeEntity] {
        try await search(with: filter).toNodeEntities()
    }
    
    public func search(filter: SearchFilterEntity, page: SearchPageEntity) async throws -> NodeListEntity {
        try await search(with: filter, page: page)
    }
    
    public func search(filter: SearchFilterEntity) async throws -> NodeListEntity {
        try await search(with: filter)
    }
    
    public func node(by handle: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    public func cancelSearch() {
        guard searchOperationQueue.operationCount > 0 else { return }
        
        searchOperationQueue.cancelAllOperations()
    }
}

extension FilesSearchRepository {
    
    private func search(with filter: SearchFilterEntity, page: SearchPageEntity? = nil, cancelToken: ThreadSafeCancelToken = ThreadSafeCancelToken(), completion: @escaping (Result<NodeListEntity, any Error>) -> Void) {
        // Don't call search if we don't want sensitive items and the parent is marked as sensitive
        if filter.recursive,
           filter.sensitiveFilterOption == .nonSensitiveOnly,
           case let .parentNode(parentNode) = filter.searchTargetLocation,
           let parentNode = sdk.node(forHandle: parentNode.handle),
           parentNode.isMarkedSensitive || sdk.isNodeInheritingSensitivity(parentNode) {
            completion(.success(NodeListEntity.emptyNodeList))
            return
        }
        
        let searchOperation = SearchWithFilterOperation(
            sdk: sdk,
            filter: filter.toMEGASearchFilter(),
            page: page?.toMEGASearchPage(),
            recursive: filter.recursive,
            sortOrder: filter.sortOrderType.toMEGASortOrderType(),
            cancelToken: cancelToken,
            completion: { nodeList, isCanceled in
                guard !isCanceled else {
                    completion(.failure(NodeSearchResultErrorEntity.cancelled))
                    return
                }
                
                guard let nodeList else {
                    completion(.failure(NodeSearchResultErrorEntity.noDataAvailable))
                    return
                }
                completion(.success(nodeList.toNodeListEntity()))
            })
        
        searchOperationQueue.addOperation(searchOperation)
    }
    
    private func search(with filter: SearchFilterEntity, page: SearchPageEntity? = nil) async throws -> NodeListEntity {
        let cancelToken = ThreadSafeCancelToken()
        return try await withTaskCancellationHandler {
            try await withAsyncThrowingValue { completion in
                search(with: filter, page: page, cancelToken: cancelToken) { completion($0) }
            }
        } onCancel: {
            if !cancelToken.value.isCancelled {
                cancelToken.value.cancel()
            }
        }
    }
}
