
public protocol VideoMediaUseCaseProtocol {
    func isPlayable(_ node: NodeEntity) -> Bool
}

public struct VideoMediaUseCase<T: VideoMediaRepositoryProtocol>: VideoMediaUseCaseProtocol {
    private let videoMediaRepository: T
    
    public init(videoMediaRepository: T) {
        self.videoMediaRepository = videoMediaRepository
    }
    
    public func isPlayable(_ node: NodeEntity) -> Bool {
        videoMediaRepository.isSupportedFormat(node.shortFormat) || videoMediaRepository.isSupportedCodec(node.codecId)
    }
}
