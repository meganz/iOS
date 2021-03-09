
protocol StreamingInfoUseCaseProtocol {
    func startServer()
    func stopServer()
    func info(from folderLinkNode: MEGANode) -> AudioPlayerItem?
    func info(from handle: MEGAHandle) -> MEGANode?
}

final class StreamingInfoUseCase: StreamingInfoUseCaseProtocol {
    
    private var streamingInfoRepository: StreamingInfoRepositoryProtocol
    
    init(streamingInfoRepository: StreamingInfoRepositoryProtocol = StreamingInfoRepository()) {
        self.streamingInfoRepository = streamingInfoRepository
    }
    
    func startServer() {
        streamingInfoRepository.serverStart()
    }
    
    func stopServer() {
        streamingInfoRepository.serverStop()
    }
    
    func info(from folderLinkNode: MEGANode) -> AudioPlayerItem? {
        streamingInfoRepository.info(fromFolderLinkNode: folderLinkNode)
    }
    
    func info(from handle: MEGAHandle) -> MEGANode? {
        streamingInfoRepository.info(fromHandle: handle)
    }
}
