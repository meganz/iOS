
import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var enableButton: UIButton!
    
    var enableButtonAction : (() -> ())?
    
    func nib() -> UINib {
        return UINib.init(nibName: "ContactsPermissionBottomView", bundle: nil)
    }
    
    func bottomReuserIdentifier() -> String {
        return "ContactsPermissionBottomViewID"
    }
    
    func configureForRequestingPermission(action: @escaping completion) {
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        enableButton.setTitle(AMLocalizedString("Enable Access", "Text indicating the user to perform an action to grant some permission"), for: .normal)
        enableButtonAction = action
    }
    
    func configureForOpenSettingsPermission(action: @escaping completion) {
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts") + "\n" + AMLocalizedString("To enable access, Settings > Privacy > Contacts > set to “On”", "Text showing the user how to grant access to contacts in the device settings")
        enableButton.setTitle(AMLocalizedString("Open Settings", "Text indicating the user to open the device settings for MEGA"), for: .normal)
        enableButtonAction = action
    }
    
    
    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
