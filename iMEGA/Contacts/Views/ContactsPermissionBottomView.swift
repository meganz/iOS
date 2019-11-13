
import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)
    
    @IBOutlet weak var accessImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var containerStackView: UIStackView!
    
    var enableButtonAction : (() -> ())?
    
    func nib() -> UINib {
        return UINib.init(nibName: "ContactsPermissionBottomView", bundle: nil)
    }
    
    func bottomReuserIdentifier() -> String {
        return "ContactsPermissionBottomViewID"
    }
    
    func configureForRequestingPermission(action: @escaping completion) {
        accessImage.isHidden = UIDevice.current.iPhone4X || UIDevice.current.iPhone5X || UIDevice.current.orientation.isLandscape
        containerStackView.layoutMargins.top = accessImage.isHidden ? 16 : 0
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        enableButton.setTitle(AMLocalizedString("Enable Access", "Text indicating the user to perform an action to grant some permission"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }
    
    func configureForOpenSettingsPermission(action: @escaping completion) {
        accessImage.isHidden = UIDevice.current.iPhone4X || UIDevice.current.iPhone5X || UIDevice.current.orientation.isLandscape
        containerStackView.layoutMargins.top = accessImage.isHidden ? 16 : 0
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        enableButton.setTitle(AMLocalizedString("Open Settings", "Text indicating the user to open the device settings for MEGA"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }
    
    
    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
