
struct FilesSearchUseCase {
    private let repo: SDKFilesSearchRepository
    private let explorerType: ExplorerTypeEntity
    
    init(repo: SDKFilesSearchRepository, explorerType: ExplorerTypeEntity) {
        self.repo = repo
        self.explorerType = explorerType
    }
    
    func search(string: String?,
                inNode node: MEGANode?,
                sortOrderType: MEGASortOrderType,
                cancelPreviousSearchIfNeeded: Bool,
                completionBlock: @escaping ([MEGANode]?) -> Void) {
        guard let formatType = MEGANodeFormatType(rawValue: explorerType.rawValue) else {
            completionBlock(nil)
            return
        }
        
        if cancelPreviousSearchIfNeeded {
            repo.cancelSearch()
        }
        
        repo.search(string: string,
                    inNode: node,
                    sortOrderType: sortOrderType,
                    formatType: formatType,
                    completionBlock: completionBlock)
        
    }
}
