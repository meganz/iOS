import UIKit

class SMSNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = true
    }

    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
}
