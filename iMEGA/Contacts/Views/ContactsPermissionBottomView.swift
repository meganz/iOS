import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var containerStackView: UIStackView!

    var enableButtonAction : (() -> Void)?

    func nib() -> UINib {
        return UINib.init(nibName: "ContactsPermissionBottomView", bundle: nil)
    }

    func bottomReuserIdentifier() -> String {
        return "ContactsPermissionBottomViewID"
    }

    func configureForRequestingPermission(action: @escaping completion) {
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        enableButton.setTitle(AMLocalizedString("Allow Access", "Button which triggers a request for a specific permission, that have been explained to the user beforehand"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }

    func configureForOpenSettingsPermission(action: @escaping completion) {
        subtitleLabel.text = AMLocalizedString("MEGA needs access to your contacts to help you connect with other people on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        enableButton.setTitle(AMLocalizedString("Open Settings", "Text indicating the user to open the device settings for MEGA"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }

    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
