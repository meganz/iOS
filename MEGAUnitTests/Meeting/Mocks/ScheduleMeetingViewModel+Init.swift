@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock

extension ScheduleMeetingViewModel {
    convenience init(
        router: some ScheduleMeetingRouting = MockScheduleMeetingRouter(),
        viewConfiguration: some ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        tracker: some AnalyticsTracking = MockTracker(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            viewConfiguration: viewConfiguration,
            accountUseCase: accountUseCase,
            preferenceUseCase: preferenceUseCase,
            featureFlagProvider: featureFlagProvider,
            tracker: tracker
        )
    }
}
