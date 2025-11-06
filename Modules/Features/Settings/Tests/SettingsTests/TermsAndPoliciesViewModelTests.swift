import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
@testable import Settings
import XCTest

final class TermsAndPoliciesViewModelTests: XCTestCase {

    private let cookieURL = URL(string: "https://mega.nz/cookie")!
    
    @MainActor
    func testSetupCookiePolicyURL_adsFlagEnabled_successSessionTransferURL_shouldReturnSessionURL() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            isExternalAdsFlagEnabled: true
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, expectedURL)
    }
    
    @MainActor
    func testSetupCookiePolicyURL_adsFlagEnabled_failedSessionTransferURL_shouldReturnDefaultURL() async throws {
        let sut = makeSUT(
            sessionTransferURLResult: .failure(.generic),
            isExternalAdsFlagEnabled: true
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, URL(fileURLWithPath: ""))
    }
    
    @MainActor
    func testSetupCookiePolicyURL_notUnderAdsExperiment_shouldReturnCookieURL() async throws {
        let domainName = "mega.app"
        let expectedURL = try XCTUnwrap(URL(string: "https://\(domainName)/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            domainNameHandler: { domainName },
            isExternalAdsFlagEnabled: false
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, URL(string: "https://mega.app/cookie")!)
    }

    // MARK: Helper
    @MainActor
    private func makeSUT(
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .success(URL(fileURLWithPath: "")),
        domainNameHandler: @escaping () -> String = { "mega.nz" },
        isExternalAdsFlagEnabled: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TermsAndPoliciesViewModel {
        
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let router = TermsAndPoliciesRouter(
            accountUseCase: accountUseCase,
            domainNameHandler: domainNameHandler
        )
        let sut = TermsAndPoliciesViewModel(
            accountUseCase: accountUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(
                list: [.externalAds: isExternalAdsFlagEnabled]
            ),
            domainNameHandler: domainNameHandler,
            router: router
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
