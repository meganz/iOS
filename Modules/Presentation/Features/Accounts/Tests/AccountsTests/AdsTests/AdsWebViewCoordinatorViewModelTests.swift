@testable import Accounts
import AccountsMock
import WebKit
import XCTest

final class AdsWebViewCoordinatorViewModelTests: XCTestCase {
    let sut = AdsWebViewCoordinatorViewModel()
    
    override func setUp() {
        super.setUp()
        _ = WKWebView()
    }

    func testShouldHandleAdsTap_navigationTypeLinkActivated_validDomainAndFrames_shouldReturnTrue() {
        let navigationAction = MockWKNavigationAction(navigationType: .linkActivated,
                                                      sourceFrame: MockWKFrameInfo(isMainFrame: false),
                                                      targetFrame: MockWKFrameInfo(isMainFrame: true))
        
        XCTAssertTrue(
            sut.shouldHandleAdsTap(currentDomain: "currentTestDomain.com",
                                   targetDomain: "targetTestDomain.com",
                                   navigationAction: navigationAction)
        )
    }
    
    func testShouldHandleAdsTap_nilTargetFrame_shouldReturnTrue() {
        let navigationAction = MockWKNavigationAction(navigationType: randomNavigationType,
                                                      sourceFrame: MockWKFrameInfo(isMainFrame: false),
                                                      targetFrame: nil)
        
        XCTAssertTrue(
            sut.shouldHandleAdsTap(currentDomain: "currentTestDomain.com",
                                   targetDomain: "targetTestDomain.com",
                                   navigationAction: navigationAction)
        )
    }
    
    func testShouldHandleAdsTap_sameCurrentDomainAndTargetDomain_shouldReturnFalse() {
        let navigationAction = MockWKNavigationAction(navigationType: randomNavigationType,
                                                      sourceFrame: MockWKFrameInfo(isMainFrame: false),
                                                      targetFrame: MockWKFrameInfo(isMainFrame: true))
        
        XCTAssertFalse(
            sut.shouldHandleAdsTap(currentDomain: "testDomain.com",
                                   targetDomain: "testDomain.com",
                                   navigationAction: navigationAction)
        )
    }
    
    func testShouldHandleAdsTap_sourceFrameIsTrue_targetFrameIsFalse_shouldReturnFalse() {
        let navigationAction = MockWKNavigationAction(navigationType: randomNavigationType,
                                                      sourceFrame: MockWKFrameInfo(isMainFrame: true),
                                                      targetFrame: MockWKFrameInfo(isMainFrame: false))
        
        XCTAssertFalse(
            sut.shouldHandleAdsTap(currentDomain: "currentTestDomain.com",
                                   targetDomain: "targetTestDomain.com",
                                   navigationAction: navigationAction)
        )
    }
    
    func testURLHostString_nilURL_shouldReturnNil() {
        XCTAssertNil(sut.urlHost(url: nil))
    }
    
    func testURLHostString_validURL_shouldReturnCorrectValue() {
        let testURL: URL? = URL(string: "https://testURL.com")
        
        let urlHost = sut.urlHost(url: testURL)
        XCTAssertNotNil(urlHost)
        XCTAssertEqual(urlHost, "testURL.com")
    }
    
    // MARK: - Helper
    private var randomNavigationType: WKNavigationType {
        let navTypes: [WKNavigationType] = [.backForward, .formResubmitted, .formSubmitted, .other, .reload]
        return navTypes.randomElement() ?? .other
    }
}
