import MEGAAssets
import UIKit

final class PrivacyViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoImageView.image = MEGAAssets.UIImage.image(named: "splashScreenMEGALogo")
    }
}
