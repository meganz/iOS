import MEGADomain

struct Preview_VisualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCaseProtocol {
    func searchQueryHistory() async throws -> [SearchTextHistoryEntryEntity] {
        []
    }
    
    func save(entries: [SearchTextHistoryEntryEntity]) async throws {
        
    }
}
