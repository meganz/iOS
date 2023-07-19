@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ScheduleMeetingViewModel {
    convenience init(
        router: some ScheduleMeetingRouting = MockScheduleMeetingRouter(),
        viewConfiguration: some ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            viewConfiguration: viewConfiguration,
            accountUseCase: accountUseCase
        )
    }
}
