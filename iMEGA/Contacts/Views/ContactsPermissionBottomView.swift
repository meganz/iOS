import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var containerStackView: UIStackView!
    
    var enableButtonAction : (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                self.updateAppearance()
            }
        }
    }
    
    private func updateAppearance() {
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        descriptionLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        
        enableButton.mnz_setupPrimary(traitCollection)
        enableButton.titleLabel?.font = UIFont.preferredFont(style: .subheadline, weight: .semibold)
    }
    
    func nib() -> UINib {
        return UINib.init(nibName: "ContactsPermissionBottomView", bundle: nil)
    }

    func bottomReuserIdentifier() -> String {
        return "ContactsPermissionBottomViewID"
    }

    func configureForRequestingPermission(action: @escaping completion) {
        configureLabels()
        enableButton.setTitle(NSLocalizedString("Allow Access", comment: "Button which triggers a request for a specific permission, that have been explained to the user beforehand"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }

    func configureForOpenSettingsPermission(action: @escaping completion) {
        configureLabels()
        enableButton.setTitle(NSLocalizedString("Open Settings", comment: "Text indicating the user to open the device settings for MEGA"), for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }
    
    private func configureLabels() {
        titleLabel.text = NSLocalizedString("Enable Access to Your Address Book", comment: "Title label that explains that the user is going to be asked for the contacts permission ");
        subtitleLabel.text = NSLocalizedString("Easily discover contacts from your address book on MEGA.", comment: "Detailed explanation of why the user should give permission to contacts")
        descriptionLabel.text = NSLocalizedString("MEGA will not use this data for any other purpose and will never interact with your contacts without your consent.", comment: "Detailed explanation about MEGA not using the contacts data without permision ");
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
