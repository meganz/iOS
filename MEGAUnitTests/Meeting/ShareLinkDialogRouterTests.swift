@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import XCTest

final class ShareLinkDialogRouterTests: XCTestCase {
    class MockSendToChatPresenting: SendToChatPresenting {
        var presented = false
        func showSendToChat(presenter: UIViewController) {
            presented = true
        }
    }
    class MockSendToChatPresentingFactory: SendToChatPresentingFactoryProtocol {
        var link: String?
        func make(link: String) -> some SendToChatPresenting {
            self.link = link
            return MockSendToChatPresenting()
        }
    }
    @MainActor
    func test_TapSendToShat() async throws {
        var _config: SimpleDialogConfig?
        let presentationHandler: PresentationHandler = { config, _ in
            _config = config
            return UIViewController()
        }
        let shareActivityFactory: ShareActivityFactory = { _, _, _ in
            UIViewController()
        }
        let sendToChatFactory = MockSendToChatPresentingFactory()
        let presenter = UIViewController()
        let router = ShareLinkDialogRouter(
            presenter: presenter,
            presentationHandler: presentationHandler,
            chatRoomUseCase: MockChatRoomUseCase(
                chatRoomEntity: ChatRoomEntity()
            ),
            chatLinkUseCase: MockChatLinkUseCase(
                link: "http://mega.co.nz"
            ),
            tracker: MockTracker(),
            sendToChatPresentingFactory: sendToChatFactory,
            shareActivityFactory: shareActivityFactory
        )
        router.showShareLinkDialog(.mockData)
        let title = Strings.Localizable.Chat.Meetings.ShareLink.sendToChat
        let button = try XCTUnwrap(_config?.button(with: title))
        let action = try XCTUnwrap(button.asyncAction)
        await action(UIView())
        XCTAssertNotNil(sendToChatFactory.link)
    }
}

extension ShareLinkRequestData {
    static var mockData: Self {
        ShareLinkRequestData(
            chatId: 123,
            title: "t",
            subtitle: "s",
            username: "u"
        )
    }
}
