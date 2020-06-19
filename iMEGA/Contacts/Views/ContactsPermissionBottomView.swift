import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
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
        configureLabels()
        enableButton.setTitle(AMLocalizedString("Allow Access", "Button which triggers a request for a specific permission, that have been explained to the user beforehand"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }

    func configureForOpenSettingsPermission(action: @escaping completion) {
        configureLabels()
        enableButton.setTitle(AMLocalizedString("Open Settings", "Text indicating the user to open the device settings for MEGA"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }
    
    private func configureLabels() {
        titleLabel.text = AMLocalizedString("Enable Access to Your Address Book", "Title label that explains that the user is going to be asked for the contacts permission ");
        subtitleLabel.text = AMLocalizedString("Easily discover contacts from your address book on MEGA.", "Detailed explanation of why the user should give permission to contacts")
        descriptionLabel.text = AMLocalizedString("MEGA will not use this data for any other purpose and will never interact with your contacts without your consent.", "Detailed explanation about MEGA not using the contacts data without permision ");
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
