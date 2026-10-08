import UIKit

/// Follows the keyboard frame, so a scroll view can add a bottom inset for the part the keyboard covers.
/// When the host already shrinks the view above the keyboard, the overlap is 0 and nothing is added twice.
@MainActor
final class KeyboardOverlap {
    /// The keyboard frame in screen coordinates. nil while it is hidden.
    private(set) var frame: CGRect?
    /// Called after the keyboard frame changed.
    var onChange: (() -> Void)?
    private var observers: [any NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            MainActor.assumeIsolated { self?.update(frame) }
        })
        observers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.update(nil) }
        })
    }

    isolated deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func update(_ newFrame: CGRect?) {
        frame = newFrame
        onChange?()
    }

    /// How far the keyboard covers the bottom of `view`, in points. 0 when it is hidden or below the view.
    func overlap(with view: UIView) -> CGFloat {
        guard let frame, let window = view.window else { return 0 }
        let viewFrame = view.convert(view.bounds, to: window.screen.coordinateSpace)
        return max(0, viewFrame.maxY - frame.minY)
    }
}
