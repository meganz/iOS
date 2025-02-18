import Accounts
import AccountsMock
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import XCTest

@MainActor
class CookieSettingsViewModelTests: XCTestCase {
    private let footersArray: [String] = [
        "", // Empty footer for the Ads personalisation menu.
        Strings.Localizable.Settings.Accept.Cookies.footer,
        Strings.Localizable.Settings.Cookies.Essential.footer,
        Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer
    ]
    
    func testConfigViewTask_numberOfSection_shouldBeFour() async {
        let sut = makeSUT()
        
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertEqual(sut.numberOfSection, 4)
    }
    
    func testAction_configView_cookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(
            viewModel: sut,
            action: .configView,
            expectedCommands: [.configCookieSettings(CookiesBitmap(rawValue: defaultCookieBits)), .updateFooters(footersArray)]
        )
    }
    
    func testAction_configView_cookieSettings_fail_bitmapNotSet() {
        let sut = makeSUT(cookieSettings: .failure(.bitmapNotSet))
        
        test(
            viewModel: sut,
            action: .configView,
            expectedCommands: [.configCookieSettings(CookiesBitmap.essential), .updateFooters(footersArray)]
        )
    }
    
    func testAction_configView_cookieSettings_fail_generic() {
        let sut = makeSUT(cookieSettings: .failure(.generic))
        
        test(
            viewModel: sut,
            action: .configView,
            expectedCommands: [.updateFooters(footersArray)]
        )
    }
    
    func testAction_configView_cookieSettings_fail_invalidBitmap() {
        let sut = makeSUT(cookieSettings: .failure(.invalidBitmap))
        
        test(
            viewModel: sut,
            action: .configView,
            expectedCommands: [.updateFooters(footersArray)]
        )
    }
    
    func testAction_save_setCookieSettings_success() {
        let sut = makeSUT(cookieSettings: .success(defaultCookieBits))
        
        test(
            viewModel: sut,
            action: .save,
            expectedCommands: [.cookieSettingsSaved]
        )
    }
    
    func testAction_showCookiePolicy_showPolicyWithoutSession() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/cookie"))
        let mockRouter = MockCookieSettingsRouter()
        let sut = makeSUT(mockRouter: mockRouter)
        
        try await checkCookiePolicyDispatchResult(
            sut: sut,
            mockRouter: mockRouter,
            expectedURL: expectedURL
        )
    }

    func testAction_showAdPrivacyOptionForm_shouldPresentAdPrivacyOptionForm() async {
        let adMobConsentManager = MockGoogleMobileAdsConsentManager(isPrivacyOptionsRequired: true)
        let sut = makeSUT(adMobConsentManager: adMobConsentManager)

        sut.dispatch(.showAdPrivacyOptionForm)
        await sut.showAdPrivacyOptionFormTask?.value
        
        XCTAssertEqual(adMobConsentManager.presentPrivacyOptionsFormCalledCount, 1)
    }
    
    func testShowAdsSettingsAndViewTitle_whenAdsIsEnabledAndPrivacyOptionsRequired_shouldReturnCorrectValues() {
        assertShowAdsSettingsAndViewTitle(
            isExternalAdsFlagEnabled: true,
            isPrivacyOptionsRequired: true,
            expectedResult: true,
            expectedViewTitle: Strings.Localizable.General.cookieAndAdSettings,
            description: "Ads is enabled and privacy options is required. ShowAdsSettings should return true with title for Cookie and ad settings."
        )
    }
    
    func testShowAdsSettingsAndViewTitle_whenAdsIsDisabled_shouldReturnCorrectValues() {
        assertShowAdsSettingsAndViewTitle(
            isExternalAdsFlagEnabled: false,
            expectedResult: false,
            expectedViewTitle: Strings.Localizable.General.cookieSettings,
            description: "Ads is disabled. ShowAdsSettings should return false with title for Cookie settings only."
        )
    }
    
    func testShowAdsSettingsAndViewTitle_whenAdPrivacyOptionsIsNotRequired_shouldReturnCorrectValues() {
        assertShowAdsSettingsAndViewTitle(
            isPrivacyOptionsRequired: false,
            expectedResult: false,
            expectedViewTitle: Strings.Localizable.General.cookieSettings,
            description: "Privacy options is not required. ShowAdsSettings should return false with title for Cookie settings only." 
        )
    }
    
    private func assertShowAdsSettingsAndViewTitle(
        isExternalAdsFlagEnabled: Bool = true,
        isPrivacyOptionsRequired: Bool = true,
        expectedResult: Bool,
        expectedViewTitle: String,
        description: String
    ) {
        let sut = makeSUT(
            isExternalAdsFlagEnabled: isExternalAdsFlagEnabled,
            adMobConsentManager: MockGoogleMobileAdsConsentManager(isPrivacyOptionsRequired: isPrivacyOptionsRequired)
        )
        XCTAssertEqual(sut.showAdsSettings, expectedResult, description)
        XCTAssertEqual(sut.viewTitle, expectedViewTitle, description)
    }
    
    func test_updateAutomaticallyAllVisibleSwitch_updatesCommand() {
        let sut = makeSUT()
        
        test(
            viewModel: sut,
            action: .acceptCookiesSwitchValueChanged(true),
            expectedCommands: [.updateAutomaticallyAllVisibleSwitch(true)]
        )
        
        test(
            viewModel: sut,
            action: .acceptCookiesSwitchValueChanged(false),
            expectedCommands: [.updateAutomaticallyAllVisibleSwitch(false)]
        )
    }
    
    // MARK: Helper
    private func checkCookiePolicyDispatchResult(
        sut: CookieSettingsViewModel,
        mockRouter: MockCookieSettingsRouter,
        expectedURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        sut.dispatch(.showCookiePolicy)
        await sut.showCookiePolicyURLTask?.value
        
        let source = try XCTUnwrap(mockRouter.source)
        if case let CookieSettingsSource.showCookiePolicy(url) = source {
            XCTAssertEqual(url, expectedURL, file: file, line: line)
        } else {
            XCTFail("Received incorrect tap source \(source)", file: file, line: line)
        }
    }
    
    // All Cookie bits: .essential, .preference, .analytics, .ads, .thirdparty
    private let defaultCookieBits = CookiesBitmap.all.rawValue // 31
    
    private func makeSUT(
        cookieBannerEnable: Bool = true,
        cookieSettings: Result<Int, CookieSettingsErrorEntity> = .success(31),
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .failure(.generic),
        mockRouter: some CookieSettingsRouting = MockCookieSettingsRouter(),
        isExternalAdsFlagEnabled: Bool = true,
        adMobConsentManager: some GoogleMobileAdsConsentManagerProtocol = MockGoogleMobileAdsConsentManager(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CookieSettingsViewModel {
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: cookieBannerEnable, cookieSettings: cookieSettings)
        let sut = CookieSettingsViewModel(
            accountUseCase: accountUseCase,
            cookieSettingsUseCase: cookieSettingsUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsFlagEnabled]),
            adMobConsentManager: adMobConsentManager,
            router: mockRouter
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

@MainActor
final class MockCookieSettingsRouter: CookieSettingsRouting {
    private(set) var source: CookieSettingsSource?
    
    nonisolated init() {}
    
    func didTap(on source: CookieSettingsSource) {
        self.source = source
    }
}
