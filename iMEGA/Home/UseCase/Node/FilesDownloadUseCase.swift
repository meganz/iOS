

final class FilesDownloadUseCase {
    private let repo: SDKTransferListenerRepository
    var nodes: [MEGANode]?
    
    init(repo: SDKTransferListenerRepository) {
        self.repo = repo
    }
    
    func addListener(nodes: [MEGANode]?,
                     start: ((MEGANode) -> Void)? = nil,
                     progress: ((MEGANode, Float, Int64) -> Void)? = nil,
                     end: @escaping (MEGANode) -> Void) {
        
        self.nodes = nodes
        
        if let start = start {
            repo.startHandler = { [weak self] inNode, isStreamingTransfer, transferType in
                guard let self = self,
                      self.nodes?.contains(inNode) != nil,
                      !isStreamingTransfer,
                      transferType == .download else {
                          return
                      }
                
                start(inNode)
            }
        }
        
        if let progress = progress {
            repo.updateHandler = { [weak self] inNode, isStreamingTransfer, transferType, progressValue, speed in
                guard let self = self,
                      self.nodes?.contains(inNode) != nil,
                      !isStreamingTransfer,
                      transferType == .download else {
                          return
                      }
                
                progress(inNode, progressValue, speed)
            }
        }
        
        repo.endHandler = { [weak self] inNode, isStreamingTransfer, transferType in
            guard let self = self,
                  self.nodes?.contains(inNode) != nil,
                  !isStreamingTransfer,
                  transferType == .download else {
                return
            }
            
            end(inNode)
        }
    }
}
