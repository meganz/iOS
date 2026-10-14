import MEGAPDFSearchInterceptor
import UIKit

@MainActor
final class PDFJumpToSearchResultScrollAdjuster: NSObject, MEGAJumpToSearchResultScrollAdjusting {
    private struct ResultPlacement {
        let rect: CGRect
        weak var rectView: UIView?
        let offsetBeforeAdjustment: CGPoint
        var offsetAfterAdjustment: CGPoint
    }

    private let contentScrollView: () -> UIScrollView?
    private(set) var keyboardRectOnScreen: CGRect = .zero
    private(set) var isKeyboardShown = false
    private var keyboardObservationTasks: [Task<Void, Never>] = []
    private var resultPlacement: ResultPlacement?
    private var contentInsetBottomWithoutKeyboard: CGFloat?

    private var scrollView: UIScrollView? { contentScrollView() }

    init(
        contentScrollView: @escaping () -> UIScrollView?,
        notificationCenter: NotificationCenter = .default
    ) {
        self.contentScrollView = contentScrollView
        super.init()
        keyboardObservationTasks = [
            Task { [weak self] in
                for await notification in notificationCenter.notifications(
                    named: UIResponder.keyboardDidChangeFrameNotification
                ) {
                    guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                        as? NSValue else { continue }
                    self?.keyboardFrameDidChange(to: value.cgRectValue)
                }
            },
            Task { [weak self] in
                for await notification in notificationCenter.notifications(
                    named: UIResponder.keyboardDidShowNotification
                ) {
                    guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                        as? NSValue else { continue }
                    self?.keyboardDidShow(at: value.cgRectValue)
                }
            },
            Task { [weak self] in
                for await _ in notificationCenter.notifications(
                    named: UIResponder.keyboardDidHideNotification
                ) {
                    self?.keyboardDidHide()
                }
            }
        ]
    }

    deinit {
        keyboardObservationTasks.forEach { $0.cancel() }
    }

    func clearResultPlacement() {
        resultPlacement = nil
        if let scrollView, let contentInsetBottomWithoutKeyboard {
            scrollView.contentInset.bottom = contentInsetBottomWithoutKeyboard
        }
        contentInsetBottomWithoutKeyboard = nil
    }

    private func keyboardDidShow(at rect: CGRect) {
        // The frame change can be observed before the keyboard counts as
        // shown, so the placement is redone once it does.
        isKeyboardShown = true
        keyboardFrameDidChange(to: rect)
    }

    private func keyboardDidHide() {
        isKeyboardShown = false
        if let scrollView, contentInsetBottomWithoutKeyboard != nil {
            updateKeyboardBottomInset(of: scrollView)
        }
    }

    private func keyboardFrameDidChange(to rect: CGRect) {
        keyboardRectOnScreen = rect
        if let scrollView, contentInsetBottomWithoutKeyboard != nil {
            updateKeyboardBottomInset(of: scrollView)
        }
        // A user scroll moves the content by more than a point; smaller
        // differences come from pixel rounding of the offset.
        guard let scrollView, var placement = resultPlacement,
              let rectView = placement.rectView,
              abs(scrollView.contentOffset.x - placement.offsetAfterAdjustment.x) < 1,
              abs(scrollView.contentOffset.y - placement.offsetAfterAdjustment.y) < 1
        else { return }

        // Re-place from PDFKit's offset so intermediate keyboard frames do not
        // leave the result above the settled frame.
        scrollView.contentOffset = placement.offsetBeforeAdjustment
        _ = placeRectIntoUsableArea(placement.rect, in: rectView, scrollView: scrollView)
        placement.offsetAfterAdjustment = scrollView.contentOffset
        resultPlacement = placement
    }

    func scrollRangeIntoUsableArea(
        _ range: UITextRange,
        in textInput: any UITextInput
    ) -> Bool {
        guard let textInputView = textInput as? UIView,
              textInput.responds(to: #selector((any UITextInput).firstRect(for:)))
        else { return false }

        let inputRect = textInput.firstRect(for: range)
        guard !inputRect.isNull, !inputRect.isInfinite, !inputRect.isEmpty else { return false }

        return scrollRectIntoUsableArea(inputRect, in: textInputView)
    }

    func scrollRectIntoUsableArea(_ rect: CGRect, in view: UIView) -> Bool {
        guard let scrollView else { return false }
        guard !rect.isNull, !rect.isInfinite, !rect.isEmpty else { return false }
        let offsetBeforeAdjustment = scrollView.contentOffset
        let contentInsetBottom = scrollView.contentInset.bottom
        let contentInsetBottomWithoutKeyboard = contentInsetBottomWithoutKeyboard
        guard placeRectIntoUsableArea(rect, in: view, scrollView: scrollView) else {
            // A declined jump falls back to PDFKit, so it leaves the scroll
            // view as it was and no placement for a keyboard change to redo.
            scrollView.contentInset.bottom = contentInsetBottom
            self.contentInsetBottomWithoutKeyboard = contentInsetBottomWithoutKeyboard
            scrollView.contentOffset = offsetBeforeAdjustment
            resultPlacement = nil
            return false
        }
        resultPlacement = ResultPlacement(
            rect: rect,
            rectView: view,
            offsetBeforeAdjustment: offsetBeforeAdjustment,
            offsetAfterAdjustment: scrollView.contentOffset
        )
        return true
    }

    private func placeRectIntoUsableArea(
        _ rect: CGRect,
        in view: UIView,
        scrollView: UIScrollView
    ) -> Bool {
        // `scrollRectToVisible` keeps the rect clear of the scroll view's
        // `adjustedContentInset`, which tracks the visible bars, so the
        // viewport excludes that inset and the keyboard is the only
        // obstruction. Its end frame includes the Find bar docked above it.
        updateKeyboardBottomInset(of: scrollView)
        // PDFKit's own jump can leave the offset past the end of the content
        // by `adjustedContentInset.bottom`, and `scrollRectToVisible` only
        // moves as far as the rect needs, so the offset is first brought within
        // the scrollable range.
        let inset = scrollView.adjustedContentInset
        let maxOffsetY = max(
            -inset.top,
            scrollView.contentSize.height + inset.bottom - scrollView.bounds.height
        )
        scrollView.contentOffset.y = min(max(scrollView.contentOffset.y, -inset.top), maxOffsetY)
        let viewport = scrollView.convert(
            scrollView.bounds.inset(by: scrollView.adjustedContentInset), to: nil
        )
        let hit = view.convert(rect, to: nil)
        guard let visibleRect = PDFSearchVisibleRect.rect(
            for: hit, in: viewport, obstructions: [keyboardRect(in: scrollView)]
        ) else { return false }

        scrollView.scrollRectToVisible(
            scrollView.convert(visibleRect, from: nil), animated: false
        )
        return true
    }

    private func keyboardRect(in scrollView: UIScrollView) -> CGRect {
        // `keyboardFrameEndUserInfoKey` is in screen coordinates, while the
        // viewport and the hit are in window coordinates. A hidden keyboard's
        // last frame can be stale, for example after a rotation. iPadOS
        // reports an undocked or floating keyboard as hidden, so it is not an
        // obstruction.
        guard isKeyboardShown else { return .zero }
        guard let window = scrollView.window else { return keyboardRectOnScreen }
        return window.convert(keyboardRectOnScreen, from: window.screen.coordinateSpace)
    }

    private func updateKeyboardBottomInset(of scrollView: UIScrollView) {
        // `PDFDisplayerView` ignores the safe area, so the keyboard never adds
        // to `adjustedContentInset`, and the end of the content cannot scroll
        // above it. The keyboard's overlap is added to `contentInset.bottom`
        // until `clearResultPlacement()` or the keyboard leaves the viewport.
        let contentInsetBottom = contentInsetBottomWithoutKeyboard
            ?? scrollView.contentInset.bottom
        var insetWithoutKeyboard = scrollView.adjustedContentInset
        insetWithoutKeyboard.bottom -= scrollView.contentInset.bottom - contentInsetBottom
        let viewportBottom = scrollView.convert(
            scrollView.bounds.inset(by: insetWithoutKeyboard), to: nil
        ).maxY
        let keyboard = keyboardRect(in: scrollView)
        let overlap = keyboard.isEmpty ? 0 : max(0, viewportBottom - keyboard.minY)
        scrollView.contentInset.bottom = contentInsetBottom + overlap
        contentInsetBottomWithoutKeyboard = overlap > 0 ? contentInsetBottom : nil
    }
}
