@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock

extension ScheduleMeetingViewModel {
    static func build(
        router: some ScheduleMeetingRouting = MockScheduleMeetingRouter(),
        viewConfiguration: some ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(valueToReturn: false),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> ScheduleMeetingViewModel {
        .init(
            router: router,
            viewConfiguration: viewConfiguration,
            accountUseCase: accountUseCase,
            preferenceUseCase: preferenceUseCase,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            tracker: tracker
        )
    }
}
