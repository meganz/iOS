@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import XCTest

class CookieSettingsViewModelTests: XCTestCase {
    private let footersArray: [String] = [Strings.Localizable.Settings.Accept.Cookies.footer,
                                               Strings.Localizable.Settings.Cookies.Essential.footer,
                                               Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer]
    
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsEnabled_shouldBeEnabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: true])
        XCTAssertTrue(sut.isFeatureFlagForInAppAdsEnabled)
    }
    
    func testIsFeatureFlagForInAppAdsEnabled_inAppAdsDisabled_shouldBeDisabled() {
        let sut = makeSUT(featureFlags: [.inAppAds: false])
        XCTAssertFalse(sut.isFeatureFlagForInAppAdsEnabled)
    }
    
    func testActionConfigView_cookieSettings_featureFlagInAppAdsEnabled_success() {
        let sut = makeSUT(featureFlags: [.inAppAds: true])
        var expectedFooters = footersArray
        expectedFooters.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: 10)), .updateFooters(expectedFooters)])
    }
    
    func testAction_configView_cookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(10))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: 10)), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_bitmapNotSet() {
        let sut = makeSUT(cookieSettings: .failure(.bitmapNotSet))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap.essential), .updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_generic() {
        let sut = makeSUT(cookieSettings: .failure(.generic))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_configView_cookieSettings_fail_invalidBitmap() {
        let sut = makeSUT(cookieSettings: .failure(.invalidBitmap))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.updateFooters(footersArray)])
    }
    
    func testAction_save_setCookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(10))
        
        test(viewModel: sut,
             action: .save,
             expectedCommands: [.cookieSettingsSaved])
    }
    
    // MARK: Helper
    private func makeSUT(
        cookieBannerEnable: Bool = true,
        cookieSettings: Result<Int, CookieSettingsErrorEntity> = .success(10),
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: false],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CookieSettingsViewModel {
        let mockRouter = MockCookieSettingsRouter()
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: cookieBannerEnable, cookieSettings: cookieSettings)
        
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter,
                                          featureFlagProvider: featureFlagProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

final class MockCookieSettingsRouter: CookieSettingsRouting {
    func didTap(on source: CookieSettingsSource) {}
}
