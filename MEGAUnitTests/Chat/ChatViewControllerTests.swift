import ChatRepoMock
@testable import MEGA
import MEGAL10n
import XCTest

@MainActor
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
    
    func testViewDidLoad_viewConfiguration_shouldBeCorrect() {
        // given
        guard let sut =  ChatContentRouter.chatViewController(for: MockChatRoom()) else { return }
        
        // when
        sut.viewDidLoad()
        
        // then
        XCTAssertNil(sut.startOrJoinCallButton.title(for: .normal))
        XCTAssertTrue(sut.startOrJoinCallButton.isHidden)
        
        XCTAssertEqual(sut.tapToReturnToCallButton.title(for: .normal), Strings.Localizable.tapToReturnToCall)
        XCTAssertTrue(sut.tapToReturnToCallButton.isHidden)
        
        XCTAssertTrue(sut.previewerView.isHidden)
        
        XCTAssertEqual(sut.navigationItem.backBarButtonItem?.title, "")
    }
}
