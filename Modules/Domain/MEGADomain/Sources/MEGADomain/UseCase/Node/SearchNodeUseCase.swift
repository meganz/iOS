import MEGAFoundation

public protocol SearchNodeUseCaseProtocol {
    func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity]
    func cancelSearch()
}

public struct SearchNodeUseCase<T: SearchNodeRepositoryProtocol>: SearchNodeUseCaseProtocol {
    private let searchNodeRepository: T
    private var debouncer: Debouncer = Debouncer(delay: 0.5)
    
    public init(searchNodeRepository: T) {
        self.searchNodeRepository = searchNodeRepository
    }
    
    public func search(type: SearchNodeTypeEntity, text: String, sortType: SortOrderEntity) async throws -> [NodeEntity] {
        cancelSearch()
        
        try await debouncer.debounce()
        return try await searchNodeRepository.search(type: type, text: text, sortType: sortType)
    }
    
    public func cancelSearch() {
        debouncer.cancel()
        searchNodeRepository.cancelSearch()
    }
}
