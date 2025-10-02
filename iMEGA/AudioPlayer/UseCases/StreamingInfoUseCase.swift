import MEGADomain

protocol StreamingInfoUseCaseProtocol: Sendable {
    func startServer()
    func stopServer()
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem?
    func isLocalHTTPServerRunning() -> Bool
    func streamingURL(for node: MEGANode) -> URL?
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
    
    func fetchTrack(from node: MEGANode) -> AudioPlayerItem? {
        streamingInfoRepository.fetchTrack(from: node)
    }
    
    func isLocalHTTPServerRunning() -> Bool {
        streamingInfoRepository.isLocalHTTPServerRunning()
    }
    
    func streamingURL(for node: MEGANode) -> URL? {
        streamingInfoRepository.streamingURL(for: node)
    }
}
