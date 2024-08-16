import Combine
@testable import MEGA
import XCTest

final class NodeDescriptionKeyboardSubscriptionsTests: XCTestCase {

    func testKeyboardDidShowNotification_shouldPublishDidShow() {
        let sut = makeSUT()
        let expectation = XCTestExpectation(description: "Should receive .didShow event")

        let cancellable = sut.publisher
            .sink { subscription in
                XCTAssertEqual(subscription, .didShow)
                expectation.fulfill()
            }

        NotificationCenter.default.post(name: UIResponder.keyboardDidShowNotification, object: nil)
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testKeyboardDidHideNotification_shouldPublishDidHide() {
        let sut = makeSUT()
        let expectation = XCTestExpectation(description: "Should receive .didHide event")

        let cancellable = sut.publisher
            .sink { subscription in
                XCTAssertEqual(subscription, .didHide)
                expectation.fulfill()
            }

        NotificationCenter.default.post(name: UIResponder.keyboardDidHideNotification, object: nil)
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    // MARK: - Helpers

    private func makeSUT() -> NodeDescriptionKeyboardSubscriptions {
        return NodeDescriptionKeyboardSubscriptions()
    }
}
