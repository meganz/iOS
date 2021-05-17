
import UIKit

extension UIViewController {
    func addRightCancelBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    func addRightDismissBarButtonItem(with title: String?) {
        let cancelBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissView))
        navigationItem.rightBarButtonItem = cancelBarButtonItem
    }
    
    @objc func dismissView() {
        dismiss(animated: true, completion: nil)
    }
}
