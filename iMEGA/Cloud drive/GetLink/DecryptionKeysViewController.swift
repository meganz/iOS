import UIKit

class DecryptionKeysViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("decryptionKey", comment: "Text related to the decryption key of a public link").localizedCapitalized
        titleLabel.text = NSLocalizedString("decryptionKey", comment: "Text related to the decryption key of a public link").localizedCapitalized
        descriptionLabel.text = NSLocalizedString("Our end-to-end encryption system requires a unique key automatically generated for this file. A link with this key is created by default, but you can export the decryption key separately for an added layer of security.", comment: "Export links dialog -> Keys tip about links and keys.")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("close", comment: "A button label. The button allows the user to close the conversation."), style: .done, target: self, action: #selector(dismissView))
    }
}
