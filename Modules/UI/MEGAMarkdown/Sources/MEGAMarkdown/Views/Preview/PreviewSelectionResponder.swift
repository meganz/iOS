import UIKit

/// Holds the preview's edit actions while a selection shows, so the edit menu and ⌘C, ⌘A reach them.
final class PreviewSelectionResponder: UIView {
    weak var controller: PreviewSelectionController?

    override var canBecomeFirstResponder: Bool { true }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(copy(_:)): controller?.selection != nil
        case #selector(selectAll(_:)): (controller?.store.count ?? 0) > 0
        default: false
        }
    }

    override func copy(_ sender: Any?) {
        controller?.copySelection()
    }

    override func selectAll(_ sender: Any?) {
        controller?.selectAll()
    }
}
