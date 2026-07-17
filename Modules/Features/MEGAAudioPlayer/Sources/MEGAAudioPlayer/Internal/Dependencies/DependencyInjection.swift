import MEGAAppSDKRepo
import MEGADomain

enum DependencyInjection {
    static var streamingRepository: some AudioStreamingRepositoryProtocol {
        AudioStreamingRepository.newRepo
    }

    static var urlResolutionUseCase: some AudioURLResolutionUseCaseProtocol {
        AudioURLResolutionUseCase(streamingRepository: streamingRepository)
    }

    static var playbackContinuationUseCase: some PlaybackContinuationUseCaseProtocol {
        PlaybackContinuationUseCase(
            previousSessionRepo: PreviousPlaybackSessionRepository.newRepo,
            minimumPlaybackTime: PlaybackContinuationUseCase<PreviousPlaybackSessionRepository>.Constants.minimumContinuationPlaybackTimeRevamp
        )
    }

    static var accountUseCase: some AccountUseCaseProtocol {
        AccountUseCase(repository: AccountRepository.newRepo)
    }
}
