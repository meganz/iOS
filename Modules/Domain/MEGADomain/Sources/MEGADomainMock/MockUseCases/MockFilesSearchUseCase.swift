import Combine
import MEGADomain
import MEGASwift

public final class MockFilesSearchUseCase: FilesSearchUseCaseProtocol, ObservableObject {
    
    public enum Message: Equatable {
        case searchLegacy
        case search
        case onNodesUpdate
        case stopNodesUpdateListener
        case startNodesUpdateListener
    }
    
    @Published public private(set) var messages = [Message]()
    
    private let searchResult: Result<[NodeEntity]?, FileSearchResultErrorEntity>
    private var onNodesUpdateResult: [NodeEntity]?
    
    private var nodesUpdateHandlers: [([MEGADomain.NodeEntity]) -> Void] = []
    
    public init(
        searchResult: Result<[NodeEntity]?, FileSearchResultErrorEntity>,
        onNodesUpdateResult: [NodeEntity]? = nil
    ) {
        self.searchResult = searchResult
        self.onNodesUpdateResult = onNodesUpdateResult
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        messages.append(.search)
        switch searchResult {
        case .success(let nodes):
            completion(nodes, false)
        case .failure:
            completion(nil, true)
        }
    }
    
    public func search(filter: SearchFilterEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        messages.append(.search)
        switch searchResult {
        case .success(let nodes):
            return nodes ?? []
        case .failure(let error):
            throw error
        }
    }
    
    public func onNodesUpdate(with nodesUpdateHandler: @escaping ([NodeEntity]) -> Void) {
        messages.append(.onNodesUpdate)
        nodesUpdateHandlers.append(nodesUpdateHandler)
    }
    
    public func simulateOnNodesUpdate(with nodes: [NodeEntity], at index: Int = 0) {
        nodesUpdateHandlers[index](nodes)
    }
    
    public func stopNodesUpdateListener() { 
        messages.append(.stopNodesUpdateListener)
    }
    
    public func startNodesUpdateListener() {
        messages.append(.startNodesUpdateListener)
    }
    
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        EmptyAsyncSequence()
            .eraseToAnyAsyncSequence()
    }
}

// MARK: - Deprecated searchApi usage
extension MockFilesSearchUseCase {
    
    public func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, cancelPreviousSearchIfNeeded: Bool, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        messages.append(.searchLegacy)
        switch searchResult {
        case .success(let nodes):
            completion(nodes, false)
        case .failure:
            completion(nil, true)
        }
    }
    
    public func search(string: String?, parent node: NodeEntity?, recursive: Bool, supportCancel: Bool, sortOrderType: SortOrderEntity, formatType: NodeFormatEntity, cancelPreviousSearchIfNeeded: Bool) async throws -> [NodeEntity] {
        messages.append(.searchLegacy)
        switch searchResult {
        case .success(let nodes):
            return nodes ?? []
        case .failure(let error):
            throw error
        }
    }
}
