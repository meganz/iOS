import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

@testable import Settings

final class TermsAndPoliciesViewModelTests: XCTestCase {

    private let cookieURL = URL(string: "https://mega.nz/cookie")!
    
    func testSetupCookiePolicyURL_featureFlagAndAdsFlagEnabled_successSessionTransferURL_shouldReturnSessionURL() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA])
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, expectedURL)
    }
    
    func testSetupCookiePolicyURL_featureFlagAndAdsFlagEnabled_failedSessionTransferURL_shouldReturnDefaultURL() async throws {
        let sut = makeSUT(
            sessionTransferURLResult: .failure(.generic),
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA])
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, URL(fileURLWithPath: ""))
    }
    
    func testSetupCookiePolicyURL_featureFlagDisabled_shouldReturnCookieURL() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            featureFlags: [.inAppAds: false],
            abTestProvider: MockABTestProvider(list: [.ads: .variantA])
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, cookieURL)
    }
    
    func testSetupCookiePolicyURL_notUnderAdsExperiment_shouldReturnCookieURL() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "https://mega.nz/testCookie"))
        let sut = makeSUT(
            sessionTransferURLResult: .success(expectedURL),
            featureFlags: [.inAppAds: true],
            abTestProvider: MockABTestProvider(list: [.ads: .baseline])
        )
        
        await sut.setupCookiePolicyURL()
        
        XCTAssertEqual(sut.cookieUrl, cookieURL)
    }

    // MARK: Helper
    private func makeSUT(
        sessionTransferURLResult: Result<URL, AccountErrorEntity> = .success(URL(fileURLWithPath: "")),
        featureFlags: [FeatureFlagKey: Bool] = [FeatureFlagKey.inAppAds: true],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA]),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TermsAndPoliciesViewModel {
        
        let accountUseCase = MockAccountUseCase(sessionTransferURLResult: sessionTransferURLResult)
        let featureFlagProvider = MockFeatureFlagProvider(list: featureFlags)
        
        let sut = TermsAndPoliciesViewModel(accountUseCase: accountUseCase,
                                            featureFlagProvider: featureFlagProvider,
                                            abTestProvider: abTestProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
