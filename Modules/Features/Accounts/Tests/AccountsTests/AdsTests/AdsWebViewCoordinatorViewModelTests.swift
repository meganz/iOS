@testable import Accounts
import Testing
import WebKit

@MainActor
struct AdsWebViewCoordinatorViewModelTests {
    let sut = AdsWebViewCoordinatorViewModel()

    @Test
    func testShouldHandleAdsTap_navigationTypeLinkActivated_validDomainAndFrames_shouldReturnTrue() {
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationType: .linkActivated,
                sourceIsMainFrame: false,
                targetIsMainFrame: true
            ) == true
        )
    }
    
    @Test
    func testShouldHandleAdsTap_nilTargetFrame_shouldReturnTrue() {
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationType: randomNavigationType,
                sourceIsMainFrame: false,
                targetIsMainFrame: nil
            ) == true
        )
    }
    
    @Test
    func testShouldHandleAdsTap_sameCurrentDomainAndTargetDomain_shouldReturnFalse() {
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "testDomain.com",
                targetDomain: "testDomain.com",
                navigationType: randomNavigationType,
                sourceIsMainFrame: false,
                targetIsMainFrame: true
            ) == false
        )
    }
    
    @Test
    func testShouldHandleAdsTap_sourceFrameIsTrue_targetFrameIsFalse_shouldReturnFalse() {
        #expect(
            sut.shouldHandleAdsTap(
                currentDomain: "currentTestDomain.com",
                targetDomain: "targetTestDomain.com",
                navigationType: randomNavigationType,
                sourceIsMainFrame: true,
                targetIsMainFrame: false
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
