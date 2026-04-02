import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASwift

protocol RecentsActionsStatesUseCaseProtocol: Sendable {
    /// Returns an async sequence that emits when recent action buckets should be refreshed.
    /// The sequence automatically throttles rapid updates, emitting at most once per interval.
    var states: AnyAsyncSequence<RecentWidgetUseCaseState> { get }
    func getLatestBucketState() async -> RecentWidgetUseCaseState
}

enum RecentWidgetUseCaseState {
    case loading
    case hidden
    case empty
    case error
    case nonEmpty([DailyRecentActionBucketGroup])
}

struct RecentsActionsStatesUseCase: RecentsActionsStatesUseCaseProtocol {
    private let homeRecentsWidgetUseCase: any HomeRecentsWidgetUseCaseProtocol
    private let recentNodesUseCase: any RecentNodesUseCaseProtocol
    private let throttleInterval: TimeInterval

    @PreferenceWrapper(key: PreferenceKeyEntity.showRecents, defaultValue: true, useCase: PreferenceUseCase.default)
    private var showRecentsPreference: Bool

    init() {
        let recentNodesUseCase = RecentNodesUseCase(
            recentNodesRepository: RecentNodesRepository.newRepo,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
            userUpdateRepository: UserUpdateRepository.newRepo,
            requestStatesRepository: RequestStatesRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )

        self.init(
            homeRecentsWidgetUseCase: HomeRecentsWidgetUseCase(),
            recentNodesUseCase: recentNodesUseCase,
            throttleInterval: 0.5,
            preferenceUseCase: PreferenceUseCase.default
        )
    }

    init(
        homeRecentsWidgetUseCase: some HomeRecentsWidgetUseCaseProtocol,
        recentNodesUseCase: some RecentNodesUseCaseProtocol,
        throttleInterval: TimeInterval,
        preferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        self.homeRecentsWidgetUseCase = homeRecentsWidgetUseCase
        self.recentNodesUseCase = recentNodesUseCase
        self.throttleInterval = throttleInterval
        $showRecentsPreference.useCase = preferenceUseCase
    }

    var states: AnyAsyncSequence<RecentWidgetUseCaseState> {
        let interval = throttleInterval
        let updates = recentNodesUseCase.recentActionBucketsUpdates

        return AsyncStream { continuation in
            let task = Task {
                var lastEmitTime: ContinuousClock.Instant?
                for await _ in updates {
                    let now = ContinuousClock.now
                    if let last = lastEmitTime, now < last + .seconds(interval) {
                        // Within throttle window, skip this event
                        continue
                    }
                    lastEmitTime = now
                    continuation.yield(await self.getLatestBucketState())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }.eraseToAnyAsyncSequence()
    }

    func getLatestBucketState() async -> RecentWidgetUseCaseState {
        guard showRecentsPreference else {
            return .hidden
        }
        do {
            let bucketGroups = try await homeRecentsWidgetUseCase.recentBuckets()
            return bucketGroups.isEmpty ? .empty : .nonEmpty(bucketGroups)
        } catch HomeRecentWidgetsErrorEntity.cancellation {
            return .empty
        } catch {
            return .error
        }
    }
}
