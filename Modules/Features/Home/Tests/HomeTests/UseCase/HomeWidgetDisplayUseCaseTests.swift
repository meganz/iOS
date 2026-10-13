@testable import Home
import MEGAPreferenceMocks
import Testing

@Suite("HomeWidgetDisplayUseCase")
struct HomeWidgetDisplayUseCaseTests {
    @Test("with no stored order, Do more with MEGA comes after Continue where you left off and before Viewed links")
    func defaultOrder() {
        let sut = HomeWidgetDisplayUseCase(preferenceUseCase: MockPreferenceUseCase())

        #expect(sut.allVisibleWidgetTypes() == [
            .shortcuts,
            .accountDetails,
            .promotionalBanners,
            .recents,
            .continueWhereYouLeft,
            .doMoreWithMega,
            .viewedLinks
        ])
    }
}
