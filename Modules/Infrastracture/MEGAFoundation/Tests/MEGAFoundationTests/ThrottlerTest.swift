 
import XCTest
@testable import MEGAFoundation

class ThrottlerTest: XCTestCase {
    func test_runThreeTimesCountOnce() {
        let expectaction = expectation(description: "Fullfill once")
        expectaction.expectedFulfillmentCount = 1

        let throttler = Throttler(timeInterval: 0.5, dispatchQueue: .main)
        throttler.start {
            expectaction.fulfill()
        }
        throttler.start {
            expectaction.fulfill()
        }
        throttler.start {
            expectaction.fulfill()
        }

        wait(for: [expectaction], timeout: 1)
    }
    
    func test_runThreeTimesCountTwice() {
        let expectaction = expectation(description: "Fullfill twice")
        expectaction.expectedFulfillmentCount = 2

        let throttler = Throttler(timeInterval: 0.5, dispatchQueue: .main)
        throttler.start {
            expectaction.fulfill()
        }
        throttler.start {
            expectaction.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
            throttler.start {
                expectaction.fulfill()
            }
        }

        wait(for: [expectaction], timeout: 1.5)
    }
}
