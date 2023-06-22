
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
    @IBOutlet private weak var modifyNumberLabel: UILabel!
    @IBOutlet private weak var removeNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = Strings.Localizable.phoneNumber
        
        phoneNumberTextLabel.text = Strings.Localizable.phoneNumber
        modifyNumberLabel.text = Strings.Localizable.modifyPhoneNumber
        removeNumberLabel.text = Strings.Localizable.removePhoneNumber
        
        guard let verifiedPhone = MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() else {
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
        
        updateAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_tertiaryBackgroundGrouped(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        tableView.reloadData()
    }
    
    private func showModifyPhoneAlert() {
        let modifyPhoneNumberAlert = UIAlertController(title: Strings.Localizable.modifyPhoneNumber, message: Strings.Localizable.thisOperationWillRemoveYourCurrentPhoneNumberAndStartTheProcessOfAssociatingANewPhoneNumberWithYourAccount, preferredStyle: .alert)
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
            MEGASdkManager.sharedMEGASdk().resetSmsVerifiedPhoneNumber(with: MEGAGenericRequestDelegate(completion: { (_, error) in
                if error.type == .apiOk {
                    let presenter = self.presentingViewController
                    self.dismiss(animated: true, completion: {
                        if let presenter = presenter {
                            AddPhoneNumberRouter(hideDontShowAgain: true, presenter: presenter).start()
                        }
                    })
                } else {
                    SVProgressHUD.showError(withStatus: Strings.Localizable.failedToRemoveYourPhoneNumberPleaseTryAgainLater)
                }
            }))
        }))
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        present(modifyPhoneNumberAlert, animated: true, completion: nil)
    }
    
    private func showRemovePhoneAlert() {
        let removePhoneNumberAlert = UIAlertController(title: Strings.Localizable.removePhoneNumber, message: Strings.Localizable.ThisWillRemoveYourAssociatedPhoneNumberFromYourAccount.ifYouLaterChooseToAddAPhoneNumberYouWillBeRequiredToVerifyIt, preferredStyle: .alert)
        removePhoneNumberAlert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
            MEGASdkManager.sharedMEGASdk().resetSmsVerifiedPhoneNumber(with: MEGAGenericRequestDelegate(completion: { (_, error) in
                if error.type == .apiOk {
                    self.dismiss(animated: true, completion: {
                        SVProgressHUD.showInfo(withStatus: Strings.Localizable.yourPhoneNumberHasBeenRemovedSuccessfully)
                    })
                } else {
                    SVProgressHUD.showError(withStatus: Strings.Localizable.failedToRemoveYourPhoneNumberPleaseTryAgainLater)
                }
            }))
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
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGrouped(traitCollection)
    }
}
