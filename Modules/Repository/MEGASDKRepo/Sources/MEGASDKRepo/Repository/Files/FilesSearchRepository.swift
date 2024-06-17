import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public final class FilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: FilesSearchRepository {
        FilesSearchRepository(sdk: MEGASdk.sharedSdk)
    }
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    private let updater: PassthroughSubject<[NodeEntity], Never>
    private let sdk: MEGASdk
    private var callback: (([NodeEntity]) -> Void)?
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        
        updater = PassthroughSubject<[NodeEntity], Never>()
        nodeUpdatesPublisher = AnyPublisher(updater)
    }
    
    // MARK: - FilesSearchRepositoryProtocol
    
    public func startMonitoringNodesUpdate(callback: (([NodeEntity]) -> Void)?) {
        self.callback = callback
        sdk.add(self)
    }
    
    public func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
    
    public func search(filter: SearchFilterEntity, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        search(filter: filter) { result in
            switch result {
            case .success(let nodes):
                completion(nodes, false)
            case .failure:
                completion(nil, true)
            }
        }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> [NodeEntity] {
        let cancelToken = MEGACancelToken()
        return try await withTaskCancellationHandler<[NodeEntity]> {
            try await withAsyncThrowingValue { completion in
                search(filter: filter, cancelToken: cancelToken) { completion($0) }
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> NodeListEntity {
        let cancelToken = MEGACancelToken()
        return try await withTaskCancellationHandler<NodeListEntity> {
            try await withAsyncThrowingValue { completion in
                search(filter: filter, cancelToken: cancelToken) { completion($0) }
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
        
    public func node(by handle: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    public func cancelSearch() {
        guard searchOperationQueue.operationCount > 0 else { return }
        
        searchOperationQueue.cancelAllOperations()
    }
    
    private func search(filter: SearchFilterEntity, cancelToken: MEGACancelToken, completion: @escaping (Result<NodeListEntity, any Error>) -> Void) {
                        
        let searchOperation = SearchWithFilterOperation(
            sdk: sdk,
            filter: filter.toMEGASearchFilter(),
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
    
    private func search(filter: SearchFilterEntity, cancelToken: MEGACancelToken = MEGACancelToken(), completion: @escaping (Result<[NodeEntity], any Error>) -> Void) {
        search(filter: filter, cancelToken: cancelToken) { result in
            completion(result.map { $0.toNodeEntities() })
        }
    }
}

// MARK: - Deprecated searchApi usage
extension FilesSearchRepository {
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       recursive: Bool,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity,
                       completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(nil, true)
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           recursive: recursive,
                           supportCancel: supportCancel,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(nodes, fail)
        }
    }
    
    public func search(string: String?,
                       parent node: NodeEntity?,
                       recursive: Bool,
                       supportCancel: Bool,
                       sortOrderType: SortOrderEntity,
                       formatType: NodeFormatEntity) async throws -> [NodeEntity] {
        return try await withCheckedThrowingContinuation({ continuation in
            search(string: string,
                   parent: node,
                   recursive: recursive,
                   supportCancel: supportCancel,
                   sortOrderType: sortOrderType,
                   formatType: formatType) {
                
                guard !Task.isCancelled else {
                    continuation.resume(throwing: FileSearchResultErrorEntity.cancelled)
                    return
                }
                
                continuation.resume(with: $0)
            }
        })
    }
    
    private func search(string: String?,
                        parent node: NodeEntity?,
                        recursive: Bool,
                        supportCancel: Bool,
                        sortOrderType: SortOrderEntity,
                        formatType: NodeFormatEntity,
                        completion: @escaping (Result<[NodeEntity], any Error>) -> Void) {
        guard let parent = node?.toMEGANode(in: sdk) ?? sdk.rootNode else {
            return completion(.failure(NodeSearchResultErrorEntity.noDataAvailable))
        }
        
        addSearchOperation(string: string,
                           parent: parent,
                           recursive: recursive,
                           supportCancel: supportCancel,
                           sortOrderType: sortOrderType,
                           formatType: formatType) { nodes, fail in
            let nodes = nodes?.toNodeEntities()
            completion(fail ? .failure(NodeSearchResultErrorEntity.noDataAvailable) : .success(nodes ?? []))
        }
    }
    
    private func addSearchOperation(string: String?,
                                    parent: MEGANode,
                                    recursive: Bool,
                                    supportCancel: Bool,
                                    sortOrderType: SortOrderEntity,
                                    formatType: NodeFormatEntity,
                                    completion: @escaping ([MEGANode]?, Bool) -> Void) {
        
        let searchOperation = SearchOperation(
            sdk: sdk,
            parentNode: parent,
            text: string ?? "",
            recursive: recursive,
            nodeFormat: formatType.toMEGANodeFormatType(),
            sortOrder: sortOrderType.toMEGASortOrderType(),
            cancelToken: MEGACancelToken(),
            completion: { nodeList, isCanceled in
                completion(nodeList?.toNodeArray(), isCanceled)
            }
        )
        searchOperationQueue.addOperation(searchOperation)
    }
}

extension FilesSearchRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let callback else {
            updater.send(nodeList?.toNodeEntities() ?? [])
            return
        }
        
        callback(nodeList?.toNodeEntities() ?? [])
    }
}
