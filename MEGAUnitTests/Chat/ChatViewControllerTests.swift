@testable import MEGA
import XCTest

final class ChatViewControllerTests: XCTestCase {
    func testbackButtonMenuTitle_NilChatTitle_IsEmptyString() {
        let title = ChatViewController.backButtonMenuTitle(chatTitle: nil, isOneToOne: false)
        XCTAssertEqual(title, "")
    }
    
    func testbackButtonMenuTitle_NonNilChatTitle_NotOneToOne_IsChatTitle() {
        let title = ChatViewController.backButtonMenuTitle(chatTitle: "TITLE", isOneToOne: false)
        XCTAssertEqual(title, "TITLE")
    }
    
    func testbackButtonMenuTitle_NonNilChatTitle_OneToOne_IsChatWithPerson() {
        let title = ChatViewController.backButtonMenuTitle(chatTitle: "PERSON", isOneToOne: true)
        XCTAssertEqual(title, "Chat with PERSON")
    }
}
