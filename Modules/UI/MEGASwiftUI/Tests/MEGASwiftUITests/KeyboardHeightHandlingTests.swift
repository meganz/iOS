import Combine
@testable import MEGASwiftUI
import MEGATest
import XCTest

final class KeyboardHeightHandlingTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testKeyboardWillShowNotification_shouldPublishNewHeight() {
        testKeyboardWillShow(with: UIResponder.keyboardWillShowNotification)
    }
    
    func testKeyboardWillChangeFrameNotification_shouldPublishNewHeight() {
        testKeyboardWillShow(with: UIResponder.keyboardWillChangeFrameNotification)
    }
    
    private func testKeyboardWillShow(
        with notificationName: Notification.Name,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = KeyboardHeightHandling(notificationCenter: notificationCenter)
        var receivedNewHeight: Bool = false
        
        let exp = expectation(description: "Keyboard height expectation")
        sut.keyboardHeightPublisher
            .sink { _ in
                receivedNewHeight = true
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        notificationCenter.post(name: notificationName, object: nil)
        
        wait(for: [exp], timeout: 0.5)
        XCTAssertTrue(receivedNewHeight, file: file, line: line)
    }
    
    func testKeyboardWillHideNotification_shouldPublishZeroHeight() {
        let sut = KeyboardHeightHandling(notificationCenter: notificationCenter)
        
        let exp = expectation(description: "Keyboard height expectation")
        sut.keyboardHeightPublisher
            .sink { height in
                XCTAssertEqual(height, 0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        notificationCenter.post(name: UIResponder.keyboardWillHideNotification, object: nil)
        wait(for: [exp], timeout: 0.5)
    }
}
