import Combine
@testable import MEGASwiftUI
import MEGASwiftUIMock
import MEGATest
import XCTest

final class KeyboardHeightStoreTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private let sampleActiveKeyboardHeight: CGFloat = 200
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testNewKeyboardHeight_shouldHaveCorrectValue() {
        let mockKeyboardHandler = MockKeyboardHeightHandling()
        let sut = makeSUT(keyboardHeightHandling: mockKeyboardHandler)
        let expectedHeight: CGFloat = sampleActiveKeyboardHeight
        
        let exp = expectation(description: "Receive new keyboard height")
        sut.$newKeyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertEqual(height, expectedHeight)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        mockKeyboardHandler.keyboardNotificationSubject.send(expectedHeight)
        wait(for: [exp], timeout: 0.5)
    }
    
    @MainActor
    func testUpdateBottomPadding_keyboardIsHidden_shouldBeZero() async {
        await testBottomPadding(newKeyboardHeight: 0)
    }
    
    @MainActor
    func testUpdateBottomPadding_keyboardIsActive_shouldBeZero() async {
        await testBottomPadding(newKeyboardHeight: sampleActiveKeyboardHeight)
    }
    
    @MainActor
    private func testBottomPadding(
        newKeyboardHeight: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(keyboardHeightHandling: MockKeyboardHeightHandling())
        let bottomViewInset: CGFloat = 100
        let expectedBottomPadding: CGFloat = newKeyboardHeight > 0 ? newKeyboardHeight - bottomViewInset : 0
        
        let exp = expectation(description: "Receive new view bottom padding")
        sut.$bottomPadding
            .dropFirst()
            .sink { padding in
                XCTAssertEqual(padding, expectedBottomPadding)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.updateBottomPadding(
            bottomViewInset: bottomViewInset,
            newKeyboardHeight: newKeyboardHeight
        )
        
        await fulfillment(of: [exp], timeout: 0.5)
    }
    
    private func makeSUT(
        keyboardHeightHandling: some KeyboardHeightHandlingProtocol,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> KeyboardHeightStore {
        let sut = KeyboardHeightStore(keyboardHandling: keyboardHeightHandling)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
