import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import UIKit

enum DependencyInjection {
    static var streamingRepository: some AudioStreamingRepositoryProtocol {
        AudioStreamingRepository.newRepo
    }

    /// Resolves a node's on-device copy
    static var localFileURLProvider: @Sendable (any PlayableNode) -> URL? {
        get { localFileURLProviderStorage.wrappedValue }
        set { localFileURLProviderStorage.mutate { $0 = newValue } }
    }

    private static let localFileURLProviderStorage = Atomic<@Sendable (any PlayableNode) -> URL?>(
        wrappedValue: { _ in nil }
    )

    static var nodeAvailabilityRepository: some AudioNodeAvailabilityRepositoryProtocol {
        AudioNodeAvailabilityRepository.newRepo
    }

    static var memoryWarningNotification: Notification.Name {
        UIApplication.didReceiveMemoryWarningNotification
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

    static var analyticsTracker: some AnalyticsTracking {
        DIContainer.tracker
    }
}
