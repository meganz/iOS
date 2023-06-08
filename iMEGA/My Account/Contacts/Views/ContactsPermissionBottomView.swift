import UIKit

class ContactsPermissionBottomView: UITableViewHeaderFooterView {

    typealias completion = (() -> Void)

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var enableButton: UIButton!
    @IBOutlet weak var containerStackView: UIStackView!
    
    var enableButtonAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.updateAppearance()
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
        enableButton.setTitle(Strings.Localizable.allowAccess, for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }

    func configureForOpenSettingsPermission(action: @escaping completion) {
        configureLabels()
        enableButton.setTitle(Strings.Localizable.openSettings, for: .normal)
        enableButtonAction = action
        contentView.layoutSubviews()
    }
    
    private func configureLabels() {
        titleLabel.text = Strings.Localizable.enableAccessToYourAddressBook
        subtitleLabel.text = Strings.Localizable.easilyDiscoverContactsFromYourAddressBookOnMEGA
        descriptionLabel.text = Strings.Localizable.megaWillNotUseThisDataForAnyOtherPurposeAndWillNeverInteractWithYourContactsWithoutYourConsent
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        enableButtonAction!()
    }
}
