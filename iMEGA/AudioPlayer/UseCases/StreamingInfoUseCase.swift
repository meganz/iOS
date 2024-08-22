import MEGADomain

protocol StreamingInfoUseCaseProtocol: Sendable {
    func startServer()
    func stopServer()
    func info(from folderLinkNode: MEGANode) -> AudioPlayerItem?
    func isLocalHTTPProxyServerRunning() -> Bool
    func path(fromNode: MEGANode) -> URL?
}

final class StreamingInfoUseCase: StreamingInfoUseCaseProtocol {
    
    private let streamingInfoRepository: any StreamingInfoRepositoryProtocol
    
    init(streamingInfoRepository: some StreamingInfoRepositoryProtocol = StreamingInfoRepository()) {
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
    
    func isLocalHTTPProxyServerRunning() -> Bool {
        streamingInfoRepository.isLocalHTTPProxyServerRunning()
    }
    
    func path(fromNode: MEGANode) -> URL? {
        streamingInfoRepository.path(fromNode: fromNode)
    }
}
