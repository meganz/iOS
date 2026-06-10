import MEGAAppSDKRepo
import MEGADomain

enum DependencyInjection {
    static var urlResolutionUseCase: some AudioURLResolutionUseCaseProtocol {
        AudioURLResolutionUseCase(
            streamingUseCase: StreamingUseCase(repository: AudioStreamingRepository.newRepo),
            folderLinkStreamingUseCase: StreamingUseCase(repository: AudioStreamingRepository.folderLinkRepo)
        )
    }
}
