import MEGAAppSDKRepo
import MEGADomain

enum DependencyInjection {
    static var streamingRepository: some AudioStreamingRepositoryProtocol {
        AudioStreamingRepository.newRepo
    }

    static var urlResolutionUseCase: some AudioURLResolutionUseCaseProtocol {
        AudioURLResolutionUseCase(streamingRepository: streamingRepository)
    }
}
