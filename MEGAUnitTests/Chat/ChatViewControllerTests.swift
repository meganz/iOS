import Chat
import ChatRepoMock
@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAUIMock
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
        let sut = makeSUT()
        
        // when
        sut.loadViewIfNeeded()
        
        // then
        XCTAssertNil(sut.startOrJoinCallButton.title(for: .normal))
        XCTAssertTrue(sut.startOrJoinCallButton.isHidden)
        
        XCTAssertEqual(sut.tapToReturnToCallButton.title(for: .normal), Strings.Localizable.tapToReturnToCall)
        XCTAssertTrue(sut.tapToReturnToCallButton.isHidden)
        
        XCTAssertTrue(sut.previewerView.isHidden)
        
        XCTAssertEqual(sut.navigationItem.backBarButtonItem?.title, "")
    }

    func testViewDidLoad_inputBarBottom_shouldFollowKeyboardLayoutGuide() {
        let sut = makeSUT()

        sut.loadViewIfNeeded()

        let bottomConstraints = sut.view.constraints.filter {
            $0.firstItem === sut.inputContainerView && $0.firstAttribute == .bottom
        }
        XCTAssertEqual(bottomConstraints.count, 1)
        XCTAssertTrue(bottomConstraints.first?.secondItem === sut.view.keyboardLayoutGuide)
    }

    private func makeSUT() -> ChatViewController {
        let chatContentViewModel = ChatContentViewModel(
            chatRoom: MockChatRoom().toChatRoomEntity(),
            chatUseCase: MockChatUseCase(),
            chatRoomUseCase: MockChatRoomUseCase(),
            chatPresenceUseCase: MockChatPresenceUseCase(),
            callUseCase: MockCallUseCase(),
            callUpdateUseCase: MockCallUpdateUseCase(),
            scheduledMeetingUseCase: MockScheduledMeetingUseCase(),
            audioSessionUseCase: MockAudioSessionUseCase(),
            transfersListenerUseCase: MockTransfersListenerUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            router: MockChatContentRouter(),
            permissionRouter: MockPermissionAlertRouter(),
            analyticsEventUseCase: MockAnalyticsEventUseCase(),
            meetingNoUserJoinedUseCase: MockMeetingNoUserJoinedUseCase(),
            handleUseCase: MockMEGAHandleUseCase(),
            callController: MockCallController(),
            callsManager: MockCallsManager(),
            noteToSelfNewFeatureBadgeStore: NoteToSelfNewFeatureBadgeStore(userAttributeUseCase: MockUserAttributeUseCase()),
            featureFlagProvider: MockFeatureFlagProvider(list: [:])
        )

        return ChatViewController(
            chatRoom: MockChatRoom().toChatRoomEntity(),
            chatContentViewModel: chatContentViewModel,
            photoPicker: MockMEGAPhotoPicker()
        )
    }
}
