@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ScheduleMeetingViewModel {
    convenience init(
        router: ScheduleMeetingRouting = MockScheduleMeetingRouter(),
        viewConfiguration: ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            viewConfiguration: viewConfiguration,
            accountUseCase: accountUseCase
        )
    }
}
