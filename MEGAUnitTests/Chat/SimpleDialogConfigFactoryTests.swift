@testable import MEGA
import MEGAL10n
import XCTest

final class SimpleDialogConfigFactoryTests: XCTestCase {
    let sendTitle = Strings.Localizable.Chat.Meetings.ShareLink.sendToChat
    let shareTitle = Strings.Localizable.Chat.Meetings.ShareLink.shareLink
    
    class Harness {
        var sut: SimpleDialogConfig!
        var sendActionTriggered = false
        var shareActionTriggered = false
        var view: UIView?
        init() {
            self.sut = SimpleDialogConfigFactory.shareLinkDialog(
                sendAction: { [unowned self] view in
                    self.sendActionTriggered = true
                    self.view = view
                },
                shareAction: {[unowned self] view in
                    self.shareActionTriggered = true
                    self.view = view
                }
            )
        }
        var buttonTitles: [String] {
            sut.buttons.map(\.title)
        }
    }
    
    func test_buttonOrder() {
        let harness = Harness()
        let expected = [sendTitle, shareTitle]
        XCTAssertEqual(expected, harness.buttonTitles)
    }
    
    @MainActor
    func test_SendActionTriggered() async throws {
        let harness = Harness()
        let action = try XCTUnwrap(harness.sut.asyncActionForButton(with: sendTitle))
        await action(UIView())
        XCTAssertTrue(harness.sendActionTriggered)
    }
    
    @MainActor
    func test_ShareActionTriggered() async throws {
        let harness = Harness()
        let action = try XCTUnwrap(harness.sut.asyncActionForButton(with: shareTitle))
        await action(UIView())
        XCTAssertTrue(harness.shareActionTriggered)
    }
}

extension SimpleDialogConfig {
    func button(with title: String) -> SimpleDialogConfig.ButtonModel? {
        buttons.first(where: { $0.title == title })
    }
    
    func asyncActionForButton(with title: String) -> AsyncViewAction? {
        button(with: title)?.asyncAction
    }
}

extension SimpleDialogConfig.ButtonModel {
    var asyncAction: (AsyncViewAction)? {
        guard case let .asyncAction(action) = self.action else {
            return nil
        }
        return action
    }
}
