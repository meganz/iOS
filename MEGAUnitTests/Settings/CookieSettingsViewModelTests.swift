
import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

class CookieSettingsViewModelTests: XCTestCase {
    private let mockRouter = MockCookieSettingsRouter()
    private let footersArray: Array<String> = [Strings.Localizable.Settings.Accept.Cookies.footer,
                                               Strings.Localizable.Settings.Cookies.Essential.footer,
                                               Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer]
    
    func testAction_configView_cookieSettings_success() {
        
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: true,
                                                              cookieSettings: .success(10))
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: 10)), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_bitmapNotSet() {
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: true,
                                                              cookieSettings: .failure(.bitmapNotSet))
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap.essential), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_generic() {
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: true)
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_invalidBitmap() {
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: true,
                                                              cookieSettings: .failure(.invalidBitmap))
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_save_setCookieSettings_success() {
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: true,
                                                              setCookieSettings: .success(10))
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
        
        test(viewModel: sut,
             action: .save,
             expectedCommands: [.cookieSettingsSaved])
    }
}

final class MockCookieSettingsRouter: CookieSettingsRouting {
    func didTap(on source: CookieSettingsSource) {}
}
