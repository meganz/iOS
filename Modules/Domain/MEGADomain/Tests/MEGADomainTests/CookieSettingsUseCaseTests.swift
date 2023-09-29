import MEGADomain
import MEGADomainMock
import XCTest

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
    
    func testCookieSetting_error_Generic() async {
        let mockError: CookieSettingsErrorEntity = .generic
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            _ = try await sut.cookieSettings()
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? CookieSettingsErrorEntity)
        }
    }
    
    func testCookieSetting_error_InvalidBitmap() async {
        let mockError: CookieSettingsErrorEntity = .invalidBitmap
        let repo = MockCookieSettingsRepository(cookieSettings: .failure(.invalidBitmap))
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            _ = try await sut.cookieSettings()
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? CookieSettingsErrorEntity)
        }
    }
    
    func testCookieSetting_error_BitmapNotSet() async {
        let mockError: CookieSettingsErrorEntity = .bitmapNotSet
        let repo = MockCookieSettingsRepository(cookieSettings: .failure(.bitmapNotSet))
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            _ = try await sut.cookieSettings()
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? CookieSettingsErrorEntity)
        }
    }
    
    func testCookieSetting_success() async {
        let mockSucess: Int = 10
        let repo = MockCookieSettingsRepository(cookieSettings: .success(mockSucess))
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            let value = try await sut.cookieSettings()
            
            XCTAssertEqual(mockSucess, value)
        } catch {
            XCTFail("errors are not expected!")
        }
        
    }
    
    func testSetCookieSetting_error_Generic() async {
        let mockError: CookieSettingsErrorEntity = .generic
        let repo = MockCookieSettingsRepository.newRepo
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            _ = try await sut.setCookieSettings(with: 10)
            
            XCTFail("error \(mockError) is expected!")
        } catch {
            XCTAssertEqual(mockError, error as? CookieSettingsErrorEntity)
        }
    }
    
    func testSetCookieSetting_success() async {
        let setting: Int = 10
        let repo = MockCookieSettingsRepository(setCookieSettings: .success(setting))
        let sut = CookieSettingsUseCase(repository: repo)
        
        do {
            let value = try await sut.setCookieSettings(with: setting)
            
            XCTAssertEqual(setting, value)
        } catch {
            XCTFail("errors are not expected!")
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
