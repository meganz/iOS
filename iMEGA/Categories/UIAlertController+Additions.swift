import Foundation

extension UIAlertController {
    func addDefaultAction(title: String, handler: ((UIAlertAction) -> Void)?) {
        let defaultAlertAction = UIAlertAction(title: title, style: .default, handler: handler)
        defaultAlertAction.mnz_setTitleTextColor(UIColor.mnz_black333333())
        addAction(defaultAlertAction)
    }
}
