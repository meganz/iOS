@testable import MEGA
import MEGAAppPresentation
import MEGADomainMock
import SwiftUI
import Testing
import UIKit

@Suite("PromoDialogInterruptibility")
@MainActor
struct PromoDialogInterruptibilityTests {

    @Test("A settled app open with nothing in the way can interrupt")
    func canInterruptUser_nothingInTheWay_isTrue() {
        #expect(makeSUT().canInterruptUser)
    }

    // MARK: - Busy user

    @Test("An active call blocks the dialog even when the call UI is not the visible screen")
    func canInterruptUser_activeCall_isFalse() {
        let sut = makeSUT(chatUseCase: MockChatUseCase(isExistingActiveCall: true))

        #expect(sut.canInterruptUser == false)
    }

    @Test("The passcode screen blocks the dialog")
    func canInterruptUser_lockScreenPresenting_isFalse() {
        #expect(makeSUT(isLockScreenPresenting: true).canInterruptUser == false)
    }

    @Test("A quota dialog already on screen takes this app open")
    func canInterruptUser_anotherDialogPresenting_isFalse() {
        #expect(makeSUT(isAnotherDialogPresenting: true).canInterruptUser == false)
    }

    // MARK: - Blocked screens
    //
    // Only the screen on top is asked. A blocked screen with something else above it is not the screen the user is
    // on, so it is the screen above that decides.

    @Test("A top screen declaring itself uninterruptible blocks the dialog")
    func canInterruptUser_blockingTopController_isFalse() {
        let sut = makeSUT(topViewController: BlockingStubViewController())

        #expect(sut.canInterruptUser == false)
    }

    @Test("A hosted SwiftUI screen blocks the dialog through its hosting controller")
    func canInterruptUser_blockingHostingControllerOnTop_isFalse() {
        let sut = makeSUT(topViewController: PromoDialogBlockingHostingController(rootView: EmptyView()))

        #expect(sut.canInterruptUser == false)
    }

    @Test("An ordinary hosted SwiftUI screen does not block the dialog")
    func canInterruptUser_unmarkedTopController_isTrue() {
        let sut = makeSUT(topViewController: UIHostingController(rootView: EmptyView()))

        #expect(sut.canInterruptUser)
    }

    @Test("A modal alert on top blocks the dialog")
    func canInterruptUser_customModalAlertOnTop_isFalse() {
        // The production conformer behind the stub above: two factor authentication and the transfer alerts
        // all arrive as this one screen.
        let sut = makeSUT(topViewController: CustomModalAlertViewController())

        #expect(sut.canInterruptUser == false)
    }

    @Test("No visible screen leaves nothing to declare itself uninterruptible")
    func canInterruptUser_noTopViewController_isTrue() {
        #expect(makeSUT(topViewController: nil).canInterruptUser)
    }

    /// The landing dialog is the one screen whose conformance is the no-stacking guarantee itself: the app-open
    /// trigger keeps no record of a dialog being up, so the dialog declaring itself uninterruptible is the only
    /// thing that stops a later app open opening a second one over it. Dropping that conformance breaks nothing
    /// else in this suite, which is why it is pinned here.
    @Test("The landing dialog blocks a second one from opening over it")
    func blockedScreens_theLandingDialogItself_conforms() {
        let landingDialog: Any.Type = PromoLandingDialogContentHostingController.self

        #expect(landingDialog as? any PromoDialogBlocking.Type != nil)
    }

    @Test("Screens outside the blocked set leave the app open alone")
    func blockedScreens_screensOutsideTheSet_doNotConform() {
        // The set is deliberately short - a call, a passcode, a modal alert, a plan screen, a quota dialog.
        // Merely important screens are not on it, and re-adding one here should be a deliberate decision.
        let accountExpired: Any.Type = AccountExpiredViewController.self
        let addPhoneNumber: Any.Type = AddPhoneNumberViewController.self

        #expect(accountExpired as? any PromoDialogBlocking.Type == nil)
        #expect(addPhoneNumber as? any PromoDialogBlocking.Type == nil)
    }

    // MARK: - Helpers

    private func makeSUT(
        chatUseCase: MockChatUseCase = MockChatUseCase(isExistingActiveCall: false),
        topViewController: UIViewController? = UIViewController(),
        isLockScreenPresenting: Bool = false,
        isAnotherDialogPresenting: Bool = false
    ) -> PromoDialogInterruptibility {
        PromoDialogInterruptibility(
            chatUseCase: chatUseCase,
            topViewController: { topViewController },
            isLockScreenPresenting: { isLockScreenPresenting },
            isAnotherDialogPresenting: { isAnotherDialogPresenting }
        )
    }
}

private final class BlockingStubViewController: UIViewController, PromoDialogBlocking {}
