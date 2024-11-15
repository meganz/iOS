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
        Strings.Localizable.Settings.Accept.Cookies.footer,
        Strings.Localizable.Settings.Cookies.Essential.footer,
        Strings.Localizable.Settings.Cookies.PerformanceAndAnalytics.footer
    ]
    
    func testConfigViewTask_numberOfSection_shouldBeThree() async {
        let sut = makeSUT()
        
        var commands = [CookieSettingsViewModel.Command]()
        sut.invokeCommand = { viewCommand in
            commands.append(viewCommand)
        }
        sut.dispatch(.configView)
        await sut.configViewTask?.value
        
        XCTAssertEqual(sut.numberOfSection, CookieSettingsViewModel.SectionType.externalAdsInactive.numberOfSections)
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CookieSettingsViewModel {
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let cookieSettingsUseCase = MockCookieSettingsUseCase(cookieBannerEnable: cookieBannerEnable, cookieSettings: cookieSettings)
        let sut = CookieSettingsViewModel(accountUseCase: accountUseCase,
                                          cookieSettingsUseCase: cookieSettingsUseCase,
                                          router: mockRouter)
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
