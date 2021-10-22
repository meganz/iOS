
import UIKit
import PhoneNumberKit

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
        
        navigationItem.title = NSLocalizedString("Phone Number", comment: "Text related to verified phone number. Used as title or cell description.")
        
        phoneNumberTextLabel.text = NSLocalizedString("Phone Number", comment: "Text related to verified phone number. Used as title or cell description.")
        modifyNumberLabel.text = NSLocalizedString("Modify Phone Number", comment: "Title for action to modify the registered phone number.")
        removeNumberLabel.text = NSLocalizedString("Remove Phone Number", comment: "Title for action to remove the registered phone number.")
        
        guard let verifiedPhone = MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() else {
            fatalError("Can not fetch verified phone number")
        }
        
        do {
            let phoneNumber = try PhoneNumberKit().parse(verifiedPhone)
            countrycodeLabel.text = "+" + String(phoneNumber.countryCode)
            phoneNumberLabel.text = PhoneNumberKit().format(phoneNumber, toType: .national)
        }
        catch {
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
    
    //MARK: - Private
    
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_tertiaryBackgroundGrouped(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        tableView.reloadData()
    }
    
    private func showModifyPhoneAlert() {
        let modifyPhoneNumberAlert = UIAlertController(title: NSLocalizedString("Modify Phone Number", comment: "Title for action to modify the registered phone number."), message: NSLocalizedString("This operation will remove your current phone number and start the process of associating a new phone number with your account.", comment: "Message for action to modify the registered phone number."), preferredStyle: .alert)
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "Button title to accept something"), style: .default, handler: { (action) in
            MEGASdkManager.sharedMEGASdk().resetSmsVerifiedPhoneNumber(with: MEGAGenericRequestDelegate(completion: { (request, error) in
                if error.type == .apiOk {
                    let presenter = self.presentingViewController
                    self.dismiss(animated: true, completion: {
                        if let presenter = presenter {
                            AddPhoneNumberRouter(hideDontShowAgain: true, presenter: presenter).start()
                        }
                    })
                } else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Failed to remove your phone number, please try again later.", comment: "A message shown to users when phone number removal fails."))
                }
            }))
        }))
        modifyPhoneNumberAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Button title to cancel something"), style: .cancel, handler: nil))
        present(modifyPhoneNumberAlert, animated: true, completion: nil)
    }
    
    private func showRemovePhoneAlert() {
        let removePhoneNumberAlert = UIAlertController(title: NSLocalizedString("Remove Phone Number", comment: "Title for action to remove the registered phone number."), message: NSLocalizedString("This will remove your associated phone number from your account. If you later choose to add a phone number you will be required to verify it.", comment: "Message for action to remove the registered phone number."), preferredStyle: .alert)
        removePhoneNumberAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "Button title to accept something"), style: .default, handler: { (action) in
            MEGASdkManager.sharedMEGASdk().resetSmsVerifiedPhoneNumber(with: MEGAGenericRequestDelegate(completion: { (request, error) in
                if error.type == .apiOk {
                    self.dismiss(animated: true, completion: {
                        SVProgressHUD.showInfo(withStatus: NSLocalizedString("Your phone number has been removed successfully.", comment: "Information message shown to users when the operation of removing phone number succeed."))
                    })
                } else {
                    SVProgressHUD.showError(withStatus: NSLocalizedString("Failed to remove your phone number, please try again later.", comment: "A message shown to users when phone number removal fails."))
                }
            }))
        }))
        removePhoneNumberAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Button title to cancel something"), style: .cancel, handler: nil))
        present(removePhoneNumberAlert, animated: true, completion: nil)
    }
    
    //MARK: - TableViewDelegate

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
