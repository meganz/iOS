import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

@testable import Settings

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
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            isExternalAdsFlagEnabled: false
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, cookieURL)
    }

    // MARK: Helper
    @MainActor
    private func makeSUT(
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .success(URL(fileURLWithPath: "")),
        isExternalAdsFlagEnabled: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TermsAndPoliciesViewModel {
        
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let router = TermsAndPoliciesRouter(accountUseCase: accountUseCase)
        let sut = TermsAndPoliciesViewModel(
            accountUseCase: accountUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsFlagEnabled]),
            router: router
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
