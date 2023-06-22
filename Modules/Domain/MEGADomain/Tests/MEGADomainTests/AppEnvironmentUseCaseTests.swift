import MEGADomain
import XCTest

final class AppEnvironmentUseCaseTests: XCTestCase {
    func testConfiguration_config() {
        let sut = AppEnvironmentUseCase.shared
        for configuration in AppConfigurationEntity.allCases {
            sut.config(configuration)
            XCTAssertEqual(sut.configuration, configuration)
        }
    }
}
