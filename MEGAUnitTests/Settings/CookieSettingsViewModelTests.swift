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
    
    func testConfigViewTask_featureFlagEnabled_adsFlagsEnabled_shouldEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [
                    .ads: .variantA,
                    .externalAds: .variantA
                ]
            )
        )
        
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertTrue(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsActive.numberOfSections)
    }
    
    func testConfigViewTask_featureFlagEnabled_adsFlagsDisabled_shouldNotEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(
                list: [
                    .ads: .variantA,
                    .externalAds: .baseline
                ]
            )
        )
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertFalse(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsInactive.numberOfSections)
    }
    
    func testConfigViewTask_featureFlagDisabled_adsFlagsDisabled_shouldNotEnableAds() async {
        let sut = makeSUT(
            featureFlags: [.inAppAds: false],
            abTestProvider: MockABTestProvider(list: [.ads: .baseline])
        )
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertFalse(sut.isExternalAdsActive)
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsInactive.numberOfSections)
    }
    
    func testActionConfigView_adsIsEnabled_adsCheckCookieNotYetSet_success() {
        var expectedFooters = footersArray
        expectedFooters.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        var expectedCookiesBit = CookiesBitmap.all
        expectedCookiesBit.remove(.ads)
        
        let noAdsCheckCookieBit = CookiesBitmap.all
        let sut = makeSUT(cookieSettings: .success(noAdsCheckCookieBit.rawValue), featureFlags: [.inAppAds: true])
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: expectedCookiesBit.rawValue)), .updateFooters(expectedFooters)])
    }
    
    func testActionConfigView_adsIsEnabled_adsCheckCookieAlreadySet_success() {
        var expectedFooters = footersArray
        expectedFooters.append(Strings.Localizable.Settings.Cookies.AdvertisingCookies.footer)
        
        var withAdsCheckCookieBit = CookiesBitmap.all
        withAdsCheckCookieBit.insert(.adsCheckCookie)
        let sut = makeSUT(cookieSettings: .success(withAdsCheckCookieBit.rawValue), featureFlags: [.inAppAds: true])
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: withAdsCheckCookieBit.rawValue)), .updateFooters(expectedFooters)])
    }
    
    func testAction_configView_cookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(viewModel: sut,
             action: .configView,
             expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: defaultCookieBits)), .updateFooters(footersArray)])
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
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(viewModel: sut,
             action: .save,
             expectedCommands: [.cookieSettingsSaved])
    }
    
    // MARK: Helper
    // All Cookie bits: .essential, .preference, .analytics, .ads, .thirdparty
    private let defaultCookieBits = CookiesBitmap.all.rawValue // 31
    
    private func makeSUT(
        cookieBannerEnable: Bool = true,
        cookieSettings: Result<Int, CookieSettingsErrorEntity> = .success(31),
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: false],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA]),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CookieSettingsViewModel {
        let mockRouter = MockCookieSettingsRouter()
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: cookieBannerEnable, cookieSettings: cookieSettings)
        
        let sut = CookieSettingsViewModel(cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter,
                                          featureFlagProvider: featureFlagProvider,
                                          abTestProvider: abTestProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

final class MockCookieSettingsRouter: CookieSettingsRouting {
    func didTap(on source: CookieSettingsSource) {}
}
