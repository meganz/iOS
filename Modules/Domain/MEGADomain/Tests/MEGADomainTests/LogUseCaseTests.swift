import XCTest
import MEGADomain
import MEGADomainMock

final class LogUseCaseTests: XCTestCase {
    func testShouldEnableLogs_debuggingEnabledByTheUser_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: true])
        let appConfig = MockAppConfigurationRepository(configuration: .debug)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_debuggingNotEnabledByTheUser_shouldReturnFalse() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppConfigurationRepository(configuration: .debug)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)

        XCTAssertFalse(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInProductionEnabledByTheUser_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: true])
        let appConfig = MockAppConfigurationRepository(configuration: .production)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInProductionNotEnabledByTheUser_shouldReturnFalse() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppConfigurationRepository(configuration: .production)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)

        XCTAssertFalse(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInQA_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppConfigurationRepository(configuration: .qa)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)

        XCTAssertTrue(sut.shouldEnableLogs())
    }
    
    func testShouldEnableLogs_appInTestFlight_shouldReturnTrue() {
        let preference = MockPreferenceUseCase(dict: [.logging: false])
        let appConfig = MockAppConfigurationRepository(configuration: .testFlight)
        let sut = LogUseCase(preferenceUseCase: preference, appConfigurationRepository: appConfig)
        XCTAssertTrue(sut.shouldEnableLogs())
    }
}
