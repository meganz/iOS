import MEGAAppSDKRepo
import MEGADesignToken
import MEGAL10n
import PhoneNumberKit
import UIKit

enum PhoneNumberTableViewSection: Int {
    case registeredPhone
    case removePhone
}

enum RegisteredPhonSectionRow: Int {
    case phone
    case modify
}

enum RemovePhoneSectionRow: Int {
    case remove
}

class PhoneNumberViewController: UITableViewController {
    
    @IBOutlet private weak var phoneNumberTextLabel: UILabel!
    @IBOutlet private weak var countrycodeLabel: UILabel!
    @IBOutlet private weak var phoneNumberLabel: UILabel!
    @IBOutlet private weak var phoneNumberImageView: UIImageView!
    @IBOutlet private weak var modifyNumberLabel: UILabel!
    @IBOutlet private weak var removeNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = Strings.Localizable.phoneNumber
        
        phoneNumberTextLabel.text = Strings.Localizable.phoneNumber
        modifyNumberLabel.text = Strings.Localizable.modifyPhoneNumber
        removeNumberLabel.text = Strings.Localizable.removePhoneNumber
        
        guard let verifiedPhone = MEGASdk.shared.smsVerifiedPhoneNumber() else {
            fatalError("Can not fetch verified phone number")
        }
        
        do {
            let phoneNumber = try PhoneNumberKit().parse(verifiedPhone)
            countrycodeLabel.text = "+" + String(phoneNumber.countryCode)
            phoneNumberLabel.text = PhoneNumberKit().format(phoneNumber, toType: .national)
        } catch {
            MEGALogError("Device contact number parser error " + verifiedPhone)
            phoneNumberLabel.text = verifiedPhone
        }
        
        setupColors()
    }
    
    // MARK: - Private
    
    private func setupColors() {
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = TokenColors.Border.strong
        phoneNumberTextLabel.textColor = TokenColors.Text.secondary
        countrycodeLabel.textColor = TokenColors.Text.secondary
        phoneNumberLabel.textColor = TokenColors.Text.primary
        modifyNumberLabel.textColor = TokenColors.Text.primary
        removeNumberLabel.textColor = TokenColors.Text.error
        phoneNumberImageView.image = UIImage.phoneNumber.withRenderingMode(.alwaysTemplate)
        phoneNumberImageView.tintColor = TokenColors.Icon.secondary
    }
    
    private func showModifyPhoneAlert() {
        let modifyPhoneNumberAlert = UIAlertController(title: Strings.Localizable.modifyPhoneNumber, message: Strings.Localizable.thisOperationWillRemoveYourCurrentPhoneNumberAndStartTheProcessOfAssociatingANewPhoneNumberWithYourAccount, preferredStyle: .alert)
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
            MEGASdk.shared.resetSmsVerifiedPhoneNumber(with: RequestDelegate { result in
                if case .success = result {
                    let presenter = self.presentingViewController
                    self.dismiss(animated: true, completion: {
                        if let presenter = presenter {
                            AddPhoneNumberRouter(hideDontShowAgain: true, presenter: presenter).start()
                        }
                    })
                } else {
                    SVProgressHUD.showError(withStatus: Strings.Localizable.failedToRemoveYourPhoneNumberPleaseTryAgainLater)
                }
            })
        }))
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        present(modifyPhoneNumberAlert, animated: true, completion: nil)
    }
    
    private func showRemovePhoneAlert() {
        let removePhoneNumberAlert = UIAlertController(title: Strings.Localizable.removePhoneNumber, message: Strings.Localizable.ThisWillRemoveYourAssociatedPhoneNumberFromYourAccount.ifYouLaterChooseToAddAPhoneNumberYouWillBeRequiredToVerifyIt, preferredStyle: .alert)
        removePhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
            MEGASdk.shared.resetSmsVerifiedPhoneNumber(with: RequestDelegate { result in
                if case .success = result {
                    self.dismiss(animated: true, completion: {
                        SVProgressHUD.showInfo(withStatus: Strings.Localizable.yourPhoneNumberHasBeenRemovedSuccessfully)
                    })
                } else {
                    SVProgressHUD.showError(withStatus: Strings.Localizable.failedToRemoveYourPhoneNumberPleaseTryAgainLater)
                }
            })
        }))
        removePhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        present(removePhoneNumberAlert, animated: true, completion: nil)
    }
    
    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == PhoneNumberTableViewSection.registeredPhone.rawValue && indexPath.row == RegisteredPhonSectionRow.modify.rawValue {
            showModifyPhoneAlert()
        } else if indexPath.section == PhoneNumberTableViewSection.removePhone.rawValue && indexPath.row == RemovePhoneSectionRow.remove.rawValue {
            showRemovePhoneAlert()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = TokenColors.Background.page
    }
}
