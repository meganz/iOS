import XCTest
import Combine
@testable import MEGASwift

final class KeyboardVisibilityHandlerTests: XCTestCase {
    var sut: KeyboardVisibilityHandler!
    var notificationCenter: NotificationCenter!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        notificationCenter = NotificationCenter()
        sut = KeyboardVisibilityHandler(notificationCenter: notificationCenter)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        sut = nil
        notificationCenter = nil
        cancellables = nil
        super.tearDown()
    }

    func testKeyboardPublisher_whenKeyboardWillShowNotificationIsPosted_shouldPublishTrue() {
        var result: Bool?
        let expectation = self.expectation(description: "Keyboard visibility expectation")
        sut.keyboardPublisher
            .sink { value in
                result = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        notificationCenter.post(name: UIResponder.keyboardWillShowNotification, object: nil)

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(result, true)
        }
    }

    func testKeyboardPublisher_whenKeyboardWillHideNotificationIsPosted_shouldPublishFalse() {
        var result: Bool?
        let expectation = self.expectation(description: "Keyboard visibility expectation")
        sut.keyboardPublisher
            .sink { value in
                result = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        notificationCenter.post(name: UIResponder.keyboardWillHideNotification, object: nil)

        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(result, false)
        }
    }
}
