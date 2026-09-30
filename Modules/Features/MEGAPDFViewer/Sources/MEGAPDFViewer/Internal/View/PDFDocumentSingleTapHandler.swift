import UIKit

@MainActor
final class PDFDocumentSingleTapHandler: NSObject {
    private let gestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.numberOfTapsRequired = 1
        return tapGestureRecognizer
    }()

    override init() {
        super.init()
        gestureRecognizer.delegate = self
    }

    func configure(on view: UIView, target: Any, action: Selector) {
        gestureRecognizer.addTarget(target, action: action)
        view.addGestureRecognizer(gestureRecognizer)
    }
}

extension PDFDocumentSingleTapHandler: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        switch otherGestureRecognizer {
        case let tap as UITapGestureRecognizer:
            tap.numberOfTapsRequired == 2
        case is UIPanGestureRecognizer, is UILongPressGestureRecognizer:
            true
        default:
            false
        }
    }
}
