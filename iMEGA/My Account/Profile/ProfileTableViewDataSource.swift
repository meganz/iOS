import UIKit
import PhoneNumberKit
import MEGAFoundation
import MEGADomain

final class ProfileTableViewDataSource {
    
    private var traitCollection: UITraitCollection
    private weak var tableView: UITableView?
    private var snapshot = NSDiffableDataSourceSnapshot<ProfileSection, ProfileSectionRow>()
    private var dataSource: ProfileTableViewDiffableDataSource?
    
    init(tableView: UITableView, traitCollection: UITraitCollection) {
        self.tableView = tableView
        self.traitCollection = traitCollection
    }
    
    func configureDataSource() {
        guard let tableView else { return }

        dataSource = ProfileTableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
            guard let self else {
                return UITableViewCell()
            }
            return configureCell(tableView: tableView, itemIdentifier: itemIdentifier, indexPath: indexPath)
        })
        dataSource?.defaultRowAnimation = .fade
    }
    
    func updateData(changes: [ProfileSection: [ProfileSectionRow]], keys: [ProfileSection]) {
        var snapshot = NSDiffableDataSourceSnapshot<ProfileSection, ProfileSectionRow>()
        snapshot.appendSections(keys)
        keys.forEach { key in
            guard let items = changes[key] else {
                return
            }
            snapshot.appendItems(items, toSection: key)
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func update(traitCollection: UITraitCollection) {
        self.traitCollection = traitCollection
        tableView?.reloadData()
    }
    
    func item(at indexPath: IndexPath) -> ProfileSectionRow? {
        dataSource?.itemIdentifier(for: indexPath)
    }
    
    private func configureCell(tableView: UITableView, itemIdentifier: ProfileSectionRow, indexPath: IndexPath) -> UITableViewCell {
        
        switch itemIdentifier {
        case .changeName:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            cell.nameLabel.text = Strings.Localizable.changeName
            return cell
        case .changePhoto:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            cell.nameLabel.text = Strings.Localizable.Account.Profile.Avatar.uploadPhoto
            return cell
        case .changeEmail(let isLoading):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            updateCellInRelationWithTwoFactorStatus(cell: cell, isLoading: isLoading)
            cell.nameLabel.text = Strings.Localizable.changeEmail
            return cell
        case .phoneNumber:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() == nil {
                cell.nameLabel.text = Strings.Localizable.addPhoneNumber
            } else {
                cell.nameLabel.text = Strings.Localizable.phoneNumber
                let phoneNumber = MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber()
                do {
                    let phone = try PhoneNumberKit().parse(phoneNumber ?? "")
                    cell.detailLabel.text = PhoneNumberKit().format(phone, toType: .international)
                } catch {
                    cell.detailLabel.text = phoneNumber
                }
                cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
            }
            return cell
        case .changePassword(let isLoading):
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.detailLabel.text = ""
            updateCellInRelationWithTwoFactorStatus(cell: cell, isLoading: isLoading)
            cell.nameLabel.text = Strings.Localizable.changePasswordLabel
            return cell
        case .recoveryKey:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecoveryKeyID", for: indexPath) as! RecoveryKeyTableViewCell
            cell.recoveryKeyContainerView.backgroundColor = UIColor.mnz_tertiaryBackgroundGrouped(traitCollection)
            cell.recoveryKeyLabel.text = Strings.Localizable.General.Security.recoveryKeyFile
            cell.backupRecoveryKeyLabel.text = Strings.Localizable.backupRecoveryKey
            cell.backupRecoveryKeyLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
            return cell
        case .upgrade:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.nameLabel.text = Strings.Localizable.upgradeAccount
            cell.selectionStyle = .default
            cell.accessoryType = MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 ? .disclosureIndicator : .none
            
            guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
                return cell
            }
            
            let accountType = accountDetails.type
            
            switch accountType {
            case .free:
                cell.detailLabel.text = Strings.Localizable.free
                cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
            case .proI:
                cell.detailLabel.text = "Pro I"
                cell.detailLabel.textColor = UIColor.mnz_redProI()
            case .proII:
                cell.detailLabel.text = "Pro II"
                cell.detailLabel.textColor = UIColor.mnz_redProII()
            case .proIII:
                cell.detailLabel.text = "Pro III"
                cell.detailLabel.textColor = UIColor.mnz_redProIII()
            case .lite:
                cell.detailLabel.text = Strings.Localizable.proLite
                cell.detailLabel.textColor = UIColor.systemOrange
            case .business:
                if MEGASdkManager.sharedMEGASdk().businessStatus == .active {
                    cell.detailLabel.text = Strings.Localizable.active
                } else {
                    cell.detailLabel.text = Strings.Localizable.paymentOverdue
                }
                cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
                cell.nameLabel.text = Strings.Localizable.business
                cell.accessoryType = .none
            case .proFlexi:
                cell.nameLabel.text = MEGAAccountDetails.string(for: accountType)
                cell.selectionStyle = .none
                cell.accessoryType = .none
            default:
                cell.detailLabel.text = "..."
            }
            return cell
        case .role:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.nameLabel.text = Strings.Localizable.upgradeAccount
            cell.selectionStyle = .default
            cell.accessoryType = MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 ? .disclosureIndicator : .none
            
            if MEGASdkManager.sharedMEGASdk().isMasterBusinessAccount {
                cell.detailLabel.text = Strings.Localizable.administrator
            } else {
                cell.detailLabel.text = Strings.Localizable.user
            }
            cell.detailLabel.textColor = UIColor.mnz_secondaryLabel()
            cell.nameLabel.text = Strings.Localizable.role.replacingOccurrences(of: ":", with: "")
            cell.accessoryType = .none
            return cell
        case .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutID", for: indexPath) as! LogoutTableViewCell
            cell.logoutLabel.text = Strings.Localizable.logoutLabel
            cell.logoutLabel.textColor = UIColor.mnz_red(for: traitCollection)
            return cell
        }
    }
    
    private func updateCellInRelationWithTwoFactorStatus(cell: ProfileTableViewCell, isLoading: Bool ) {
        if isLoading {
            cell.nameLabel?.isEnabled = false
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            cell.accessoryView = activityIndicator
        } else {
            cell.nameLabel?.isEnabled = true
            cell.accessoryView = nil
        }
    }
}
