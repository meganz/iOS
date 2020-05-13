import UIKit

class SMSNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = true
        navigationBar.tintColor = UIColor.mnz_redMain()
    }

    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .all
    }
}
