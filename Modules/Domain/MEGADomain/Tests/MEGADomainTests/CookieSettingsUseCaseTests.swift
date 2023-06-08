
import XCTest
import MEGADomain
import MEGADomainMock

final class CookieSettingsUseCaseTests: XCTestCase {
    
    func testCookieBanner_enable() {
        let repo = MockCookieSettingsRepository(cookieBannerEnable: true)
        let sut = CookieSettingsUseCase(repository: repo)
        XCTAssertTrue(sut.cookieBannerEnabled())
    }
    
    func testCookieBanner_disable() {
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        XCTAssertFalse(sut.cookieBannerEnabled())
    }
    
    func testCookieSetting_error_Generic() {
        let mockError: CookieSettingsErrorEntity = .generic
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        sut.cookieSettings { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func testCookieSetting_error_InvalidBitmap() {
        let mockError: CookieSettingsErrorEntity = .invalidBitmap
        let repo = MockCookieSettingsRepository(cookieSettings: .failure(.invalidBitmap))
        let sut = CookieSettingsUseCase(repository: repo)
        sut.cookieSettings { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func testCookieSetting_error_BitmapNotSet() {
        let mockError: CookieSettingsErrorEntity = .bitmapNotSet
        let repo = MockCookieSettingsRepository(cookieSettings: .failure(.bitmapNotSet))
        let sut = CookieSettingsUseCase(repository: repo)
        sut.cookieSettings { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func testCookieSetting_success() {
        let mockSucess: Int = 10
        let repo = MockCookieSettingsRepository(cookieSettings: .success(mockSucess))
        let sut = CookieSettingsUseCase(repository: repo)
        sut.cookieSettings { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(mockSucess, value)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func testSetCookieSetting_error_Generic() {
        let mockError: CookieSettingsErrorEntity = .generic
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        sut.setCookieSettings(with: 10) { result in
            switch result {
            case .success:
                XCTFail("error \(mockError) is expected!")
            case .failure(let error):
                XCTAssertEqual(mockError, error)
            }
        }
    }
    
    func testSetCookieSetting_success() {
        let setting: Int = 10
        let repo = MockCookieSettingsRepository(setCookieSettings: .success(setting))
        let sut = CookieSettingsUseCase(repository: repo)
        sut.setCookieSettings(with: setting) { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(setting, value)
            case .failure:
                XCTFail("errors are not expected!")
            }
        }
    }
    
    func test_enableCrashlytics() {
        let enable = true
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        sut.setCrashlyticsEnabled(enable)
        XCTAssertTrue(enable)
    }
    
    func test_disableCrashlytics() {
        let enable = false
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        sut.setCrashlyticsEnabled(enable)
        XCTAssertFalse(enable)
    }
}
