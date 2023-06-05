
struct NodeClipboardOperationUseCase {
    private let repo: SDKNodeClipboardOperationRepository
    
    init(repo: SDKNodeClipboardOperationRepository) {
        self.repo = repo
    }
    
    func onNodeMove(withCompletionBlock completionBlock: @escaping (MEGANode) -> Void) {
        repo.onClipboardOperationComplete(permittedOperations: [.move], withCompletionBlock: completionBlock)
    }
    
    func onNodeCopy(withCompletionBlock completionBlock: @escaping (MEGANode) -> Void) {
        repo.onClipboardOperationComplete(permittedOperations: [.copy], withCompletionBlock: completionBlock)
    }
}
