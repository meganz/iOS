import UIKit

public extension UIAlertController {
    func addAction(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: (() -> Void)? = nil
    ) {
        addAction(
            UIAlertAction(
                title: title,
                style: style,
                handler: { _ in
                    handler?()
                }
            )
        )
    }
}
