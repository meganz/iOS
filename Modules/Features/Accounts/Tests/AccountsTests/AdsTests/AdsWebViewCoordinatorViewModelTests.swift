@testable import Accounts
import AccountsMock
import Testing
import WebKit

@MainActor
struct AdsWebViewCoordinatorViewModelTests {
    let sut = AdsWebViewCoordinatorViewModel()
    /// this dummy webView is needed, otherwise the test crashes due to WKNavigationAction deallocation.
    /// Ref: https://stackoverflow.com/questions/69736487/releasing-wknavigationaction-subclass-crashes-on-ios-15
    let webView = WKWebView()

    @Test
    func testShouldHandleAdsTap_navigationTypeLinkActivated_validDomainAndFrames_shouldReturnTrue() {
        let navigationAction = MockWKNavigationAction(
            navigationType: .linkActivated,
            sourceFrame: MockWKFrameInfo(isMainFrame: false),
            targetFrame: MockWKFrameInfo(isMainFrame: true)
        )
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationAction: navigationAction
            ) == true
        )
    }
    
    @Test
    func testShouldHandleAdsTap_nilTargetFrame_shouldReturnTrue() {
        let navigationAction = MockWKNavigationAction(
            navigationType: randomNavigationType,
            sourceFrame: MockWKFrameInfo(isMainFrame: false),
            targetFrame: nil
        )
        
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationAction: navigationAction
            ) == true
        )
    }
    
    @Test
    func testShouldHandleAdsTap_sameCurrentDomainAndTargetDomain_shouldReturnFalse() {
        let navigationAction = MockWKNavigationAction(
            navigationType: randomNavigationType,
            sourceFrame: MockWKFrameInfo(isMainFrame: false),
            targetFrame: MockWKFrameInfo(isMainFrame: true)
        )
        
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "testDomain.com",
                targetDomain: "testDomain.com",
                navigationAction: navigationAction
            ) == false
        )
    }
    
    @Test
    func testShouldHandleAdsTap_sourceFrameIsTrue_targetFrameIsFalse_shouldReturnFalse() {
        let navigationAction = MockWKNavigationAction(
            navigationType: randomNavigationType,
            sourceFrame: MockWKFrameInfo(isMainFrame: true),
            targetFrame: MockWKFrameInfo(isMainFrame: false)
        )
        
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationAction: navigationAction
            ) == false
        )
    }
    
    @Test
    func testURLHostString_nilURL_shouldReturnNil() {
        #expect(sut.urlHost(url: nil) == nil)
    }
    
    @Test
    func testURLHostString_validURL_shouldReturnCorrectValue() {
        let testURL: URL? = URL(string: "https://testURL.com")
        
        let urlHost = sut.urlHost(url: testURL)
        #expect(urlHost != nil)
        #expect(urlHost == "testURL.com")
    }
    
    // MARK: - Helper
    private var randomNavigationType: WKNavigationType {
        let navTypes: [WKNavigationType] = [.backForward, .formResubmitted, .formSubmitted, .other, .reload]
        return navTypes.randomElement() ?? .other
    }
}
