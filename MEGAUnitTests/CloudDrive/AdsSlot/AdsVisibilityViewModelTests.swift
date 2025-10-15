@testable import MEGA
import XCTest

@MainActor
final class AdsVisibilityViewModelTests: XCTestCase {
    class MockAdsVisibilityConfigurator: AdsVisibilityConfigurating {
        
        var configureAdsVisibilityRecorder = FuncCallRecorder<Void, Void>()
        
        func configureAdsVisibility() {
            configureAdsVisibilityRecorder.call()
        }
    }
    
    func testConfigureAdsVisibility() {
        // given
        let configurator = MockAdsVisibilityConfigurator()
        let sut = AdsVisibilityViewModel { configurator }
        
        // when
        sut.configureAdsVisibility()
        
        // then
        XCTAssertTrue(configurator.configureAdsVisibilityRecorder.called)
        
    }
}
