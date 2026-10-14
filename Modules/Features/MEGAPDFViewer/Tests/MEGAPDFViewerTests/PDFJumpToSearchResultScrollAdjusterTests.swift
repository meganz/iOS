@testable import MEGAPDFViewer
import Testing
import UIKit

@MainActor
struct PDFJumpToSearchResultScrollAdjusterTests {
    @Test func contentRectBehindKeyboard_scrollsAboveKeyboard() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let finalHit = content.convert(hit, to: nil)
        #expect(finalHit.minY >= 0)
        #expect(finalHit.maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardFrameChangeAfterScroll_rescrollsResultAboveKeyboard() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        // The hit is visible before the keyboard arrives.
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))

        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)

        let finalHit = content.convert(hit, to: nil)
        #expect(finalHit.maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardShowThroughIntermediateFrame_landsAtSettledFrame() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let intermediate = CGRect(x: 0, y: 450, width: 320, height: 250)
        await postKeyboardFrame(intermediate, to: notificationCenter, until: scrollAdjuster)
        let settled = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(settled, to: notificationCenter, until: scrollAdjuster)

        #expect(abs(content.convert(hit, to: nil).maxY - settled.minY) < 1)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardDismissThroughIntermediateFrame_replacesBelowKeyboard() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let initialOffset = scrollView.contentOffset
        let intermediate = CGRect(x: 0, y: 450, width: 320, height: 250)
        await postKeyboardFrame(intermediate, to: notificationCenter, until: scrollAdjuster)
        #expect(scrollView.contentOffset.y > initialOffset.y)
        let settled = CGRect(x: 0, y: 650, width: 320, height: 50)
        await postKeyboardFrame(settled, to: notificationCenter, until: scrollAdjuster)

        #expect(scrollView.contentOffset.y < initialOffset.y)
        #expect(content.convert(hit, to: nil).maxY <= window.bounds.maxY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardFrameChangeAfterSubPointOffsetDrift_replacesResult() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        // A fraction of a point, as layout rounding could produce.
        scrollView.contentOffset.y += 0.25
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)

        #expect(content.convert(hit, to: nil).maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardFrameChangeAfterUserScroll_doesNotReplaceResult() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        scrollView.contentOffset.y += 20
        let userOffset = scrollView.contentOffset
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )

        #expect(scrollView.contentOffset == userOffset)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardFrameChangeAfterClearingResultPlacement_doesNotScroll() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let offsetBeforeKeyboard = scrollView.contentOffset

        scrollAdjuster.clearResultPlacement()
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)

        #expect(scrollView.contentOffset == offsetBeforeKeyboard)
        withExtendedLifetime(window) {}
    }

    @Test func contentRectBehindKeyboardOverBottomInset_landsAtKeyboardTop() async {
        let (window, scrollView, content) = makeScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset.bottom = 50
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        // The keyboard covers the 50pt bottom inset, so the inset must not
        // push the hit further up than the keyboard top.
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let finalHit = content.convert(hit, to: nil)
        #expect(finalHit.maxY <= keyboard.minY)
        #expect(finalHit.maxY >= keyboard.minY - 1)
        withExtendedLifetime(window) {}
    }

    @Test func contentRectUnderTopInset_scrollsBelowInset() {
        let (window, scrollView, content) = makeScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset.top = 100
        scrollView.contentOffset.y = 600
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: NotificationCenter()
        )
        // Content y 620 sits at window y 20, under the 100pt top inset.
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let finalHit = content.convert(hit, to: nil)
        #expect(finalHit.minY >= 100)
        #expect(finalHit.maxY <= 700)
        withExtendedLifetime(window) {}
    }

    @Test func contentRectAtEndOfContentBehindKeyboard_scrollsAboveKeyboard() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        // Clearing the keyboard needs an offset of 970, past the 800 that a
        // 1500pt content in a 700pt viewport allows without extra inset.
        let hit = CGRect(x: 0, y: 1450, width: 40, height: 20)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        #expect(content.convert(hit, to: nil).maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func clearingResultPlacement_removesKeyboardBottomInset() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let insetBeforeKeyboard = scrollView.contentInset
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 1450, width: 40, height: 20), in: content
        ))
        #expect(scrollView.contentInset.bottom > insetBeforeKeyboard.bottom)

        scrollAdjuster.clearResultPlacement()

        #expect(scrollView.contentInset == insetBeforeKeyboard)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardHiddenAfterScroll_removesKeyboardBottomInset() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let insetBeforeKeyboard = scrollView.contentInset
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )
        #expect(scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 1450, width: 40, height: 20), in: content
        ))
        #expect(scrollView.contentInset.bottom > insetBeforeKeyboard.bottom)

        await postKeyboardFrame(
            CGRect(x: 0, y: 700, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )

        #expect(scrollView.contentInset == insetBeforeKeyboard)
        withExtendedLifetime(window) {}
    }

    @Test func windowOffsetFromScreen_measuresKeyboardInWindowSpace() async {
        let (window, scrollView, content) = makeScrollView(
            windowFrame: CGRect(x: 0, y: 100, width: 320, height: 700)
        )
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        // Screen y 600 is window y 500.
        let keyboardOnScreen = CGRect(x: 0, y: 600, width: 320, height: 200)
        await postKeyboardFrame(keyboardOnScreen, to: notificationCenter, until: scrollAdjuster)
        let hit = CGRect(x: 0, y: 620, width: 40, height: 20)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        #expect(content.convert(hit, to: nil).maxY <= 500)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardShownAfterItsFrameChange_replacesResultAboveKeyboard() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let hit = CGRect(x: 0, y: 540, width: 40, height: 20)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrameChangeOnly(keyboard, to: notificationCenter, until: scrollAdjuster)
        #expect(content.convert(hit, to: nil).maxY > keyboard.minY)

        await postKeyboardShowOnly(keyboard, to: notificationCenter, until: scrollAdjuster)

        #expect(content.convert(hit, to: nil).maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardCoveringViewport_declinesWithoutMovingContent() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )
        #expect(scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 620, width: 40, height: 20), in: content
        ))
        await postKeyboardFrame(
            CGRect(x: 0, y: 0, width: 320, height: 700),
            to: notificationCenter,
            until: scrollAdjuster
        )
        let offsetBeforeJump = scrollView.contentOffset
        let insetBeforeJump = scrollView.contentInset

        #expect(!scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 620, width: 40, height: 20), in: content
        ))
        #expect(scrollView.contentOffset == offsetBeforeJump)
        #expect(scrollView.contentInset == insetBeforeJump)

        // A declined jump leaves no placement for a keyboard change to redo.
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )
        #expect(scrollView.contentOffset == offsetBeforeJump)
        withExtendedLifetime(window) {}
    }

    @Test func offsetPastEndOfContent_isBroughtWithinScrollRange() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let keyboard = CGRect(x: 0, y: 500, width: 320, height: 200)
        await postKeyboardFrame(keyboard, to: notificationCenter, until: scrollAdjuster)
        #expect(scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 620, width: 40, height: 20), in: content
        ))
        // With the keyboard's 200pt bottom inset, the furthest offset is
        // 1500 + 200 - 700. PDFKit's own jump overshoots it by the inset,
        // leaving the hit already clear of bars and keyboard.
        let maxOffsetY: CGFloat = 1000
        scrollView.contentOffset.y = maxOffsetY + 200
        let hit = CGRect(x: 0, y: 1400, width: 40, height: 14)
        #expect(content.convert(hit, to: nil).minY >= 100)
        #expect(content.convert(hit, to: nil).maxY <= keyboard.minY)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        #expect(scrollView.contentOffset.y <= maxOffsetY + 0.5)
        let finalHit = content.convert(hit, to: nil)
        #expect(finalHit.minY >= 0)
        #expect(finalHit.maxY <= keyboard.minY)
        withExtendedLifetime(window) {}
    }

    @Test func keyboardHiddenWithoutFrameChange_removesKeyboardBottomInset() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let insetBeforeKeyboard = scrollView.contentInset
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )
        #expect(scrollAdjuster.scrollRectIntoUsableArea(
            CGRect(x: 0, y: 1450, width: 40, height: 20), in: content
        ))
        #expect(scrollView.contentInset.bottom > insetBeforeKeyboard.bottom)

        await hideKeyboard(on: notificationCenter, until: scrollAdjuster)

        #expect(scrollView.contentInset == insetBeforeKeyboard)
        withExtendedLifetime(window) {}
    }

    @Test func jumpAfterKeyboardHides_ignoresLastKeyboardFrame() async {
        let (window, scrollView, content) = makeScrollView()
        let notificationCenter = NotificationCenter()
        let scrollAdjuster = PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { scrollView },
            notificationCenter: notificationCenter
        )
        let insetBeforeKeyboard = scrollView.contentInset
        await postKeyboardFrame(
            CGRect(x: 0, y: 500, width: 320, height: 200),
            to: notificationCenter,
            until: scrollAdjuster
        )
        await hideKeyboard(on: notificationCenter, until: scrollAdjuster)
        let offsetBeforeJump = scrollView.contentOffset
        // Visible without a keyboard, behind the keyboard's last frame, with
        // the content offset by the window's top safe area.
        let hit = CGRect(x: 0, y: 540, width: 40, height: 20)
        #expect(content.convert(hit, to: nil).minY >= 500)

        #expect(scrollAdjuster.scrollRectIntoUsableArea(hit, in: content))
        #expect(scrollView.contentOffset == offsetBeforeJump)
        #expect(scrollView.contentInset == insetBeforeKeyboard)
        withExtendedLifetime(window) {}
    }

    private func makeScrollView(
        windowFrame: CGRect = CGRect(x: 0, y: 0, width: 320, height: 700)
    ) -> (UIWindow, UIScrollView, UIView) {
        let window = UIWindow(frame: windowFrame)
        let scrollView = UIScrollView(frame: window.bounds)
        let content = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1500))
        scrollView.contentSize = content.bounds.size
        scrollView.addSubview(content)
        window.addSubview(scrollView)
        window.makeKeyAndVisible()
        return (window, scrollView, content)
    }

    private func postKeyboardFrame(
        _ frame: CGRect,
        to notificationCenter: NotificationCenter,
        until scrollAdjuster: PDFJumpToSearchResultScrollAdjuster
    ) async {
        // The adjuster subscribes from a `Task`, so a single post can arrive
        // before the subscription exists.
        let userInfo = [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
        for _ in 0..<100 where !scrollAdjuster.isKeyboardShown
            || scrollAdjuster.keyboardRectOnScreen != frame {
            notificationCenter.post(
                name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo
            )
            notificationCenter.post(
                name: UIResponder.keyboardDidChangeFrameNotification,
                object: nil,
                userInfo: userInfo
            )
            await Task.yield()
        }
        await Task.yield()
    }

    private func postKeyboardFrameChangeOnly(
        _ frame: CGRect,
        to notificationCenter: NotificationCenter,
        until scrollAdjuster: PDFJumpToSearchResultScrollAdjuster
    ) async {
        for _ in 0..<100 where scrollAdjuster.keyboardRectOnScreen != frame {
            notificationCenter.post(
                name: UIResponder.keyboardDidChangeFrameNotification,
                object: nil,
                userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
            )
            await Task.yield()
        }
        await Task.yield()
    }

    private func postKeyboardShowOnly(
        _ frame: CGRect,
        to notificationCenter: NotificationCenter,
        until scrollAdjuster: PDFJumpToSearchResultScrollAdjuster
    ) async {
        for _ in 0..<100 where !scrollAdjuster.isKeyboardShown {
            notificationCenter.post(
                name: UIResponder.keyboardDidShowNotification,
                object: nil,
                userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame)]
            )
            await Task.yield()
        }
        await Task.yield()
    }

    private func hideKeyboard(
        on notificationCenter: NotificationCenter,
        until scrollAdjuster: PDFJumpToSearchResultScrollAdjuster
    ) async {
        for _ in 0..<100 where scrollAdjuster.isKeyboardShown {
            notificationCenter.post(name: UIResponder.keyboardDidHideNotification, object: nil)
            await Task.yield()
        }
        await Task.yield()
    }
}
