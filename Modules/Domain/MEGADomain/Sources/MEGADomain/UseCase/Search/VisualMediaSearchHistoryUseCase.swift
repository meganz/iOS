public protocol VisualMediaSearchHistoryUseCaseProtocol: Sendable {
    func searchQueryHistory() async throws -> [SearchTextHistoryEntryEntity]
    func save(entries: [SearchTextHistoryEntryEntity]) async throws
}

// Implement in CC-7985
public struct VisualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCaseProtocol {
    public init() {
        
    }
    
    public func searchQueryHistory() async throws -> [SearchTextHistoryEntryEntity] {
        []
    }
    
    public func save(entries: [SearchTextHistoryEntryEntity]) async throws {
        
    }
}
