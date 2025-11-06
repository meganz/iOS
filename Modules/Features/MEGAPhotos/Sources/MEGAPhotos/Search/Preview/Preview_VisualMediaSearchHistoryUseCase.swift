import MEGADomain

struct Preview_VisualMediaSearchHistoryUseCase: VisualMediaSearchHistoryUseCaseProtocol {
    func history() async -> [SearchTextHistoryEntryEntity] {
        []
    }
    
    func add(entry: SearchTextHistoryEntryEntity) async {
        
    }
}
