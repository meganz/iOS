final class BrowserViewControllerDelegateHandler: NSObject, BrowserViewControllerDelegate {
    var endEditingMode: (() -> Void)?
    func nodeEditCompleted(_ complete: Bool) {
        endEditingMode?()
    }
}
