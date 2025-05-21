import MEGAAssets
import MEGAL10n
import UIKit

class DecryptionKeysViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Localizable.decryptionKey.localizedCapitalized
        titleLabel.text = Strings.Localizable.decryptionKey.localizedCapitalized
        descriptionLabel.text = Strings.Localizable.OurEndToEndEncryptionSystemRequiresAUniqueKeyAutomaticallyGeneratedForThisFile.aLinkWithThisKeyIsCreatedByDefaultButYouCanExportTheDecryptionKeySeparatelyForAnAddedLayerOfSecurity
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .done, target: self, action: #selector(dismissView))
        imageView.image = MEGAAssets.UIImage.image(named: "decryptionKeyIllustration")
    }
}
