import Accounts
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGASwiftUI
import PhoneNumberKit
import UIKit

final class ProfileTableViewDataSource {
    
    private var traitCollection: UITraitCollection
    private weak var tableView: UITableView?
    private var snapshot = NSDiffableDataSourceSnapshot<ProfileSection, ProfileSectionRow>()
    private var dataSource: ProfileTableViewDiffableDataSource?
    private let parent: UIViewController
    
    init(
        tableView: UITableView,
        parent: UIViewController,
        traitCollection: UITraitCollection
    ) {
        self.tableView = tableView
        self.parent = parent
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
            if MEGASdk.shared.smsVerifiedPhoneNumber() == nil {
                cell.nameLabel.text = Strings.Localizable.addPhoneNumber
            } else {
                cell.nameLabel.text = Strings.Localizable.phoneNumber
                let phoneNumber = MEGASdk.shared.smsVerifiedPhoneNumber()
                do {
                    let phone = try PhoneNumberKit().parse(phoneNumber ?? "")
                    cell.detailLabel.text = PhoneNumberKit().format(phone, toType: .international)
                } catch {
                    cell.detailLabel.text = phoneNumber
                }
                cell.detailLabel.textColor = TokenColors.Text.secondary
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
            cell.recoveryKeyContainerView.backgroundColor = TokenColors.Background.surface1
            cell.recoveryKeyLabel.text = Strings.Localizable.General.Security.recoveryKeyFile
            cell.backupRecoveryKeyLabel.text = Strings.Localizable.backupRecoveryKey
            cell.backupRecoveryKeyLabel.textColor = TokenColors.Link.primary
            return cell
        case .upgrade:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCellID", for: indexPath) as! ProfileTableViewCell
            cell.nameLabel.text = Strings.Localizable.upgradeAccount
            cell.selectionStyle = .default
            cell.accessoryType = MEGAPurchase.sharedInstance()?.products?.count ?? 0 > 0 ? .disclosureIndicator : .none
            
            guard let accountDetails = MEGASdk.shared.mnz_accountDetails else {
                return cell
            }
            
            let accountType = accountDetails.type
            
            switch accountType {
            case .free:
                cell.detailLabel.text = Strings.Localizable.free
                cell.detailLabel.textColor = TokenColors.Text.secondary
            case .proI:
                cell.detailLabel.text = "Pro I"
                cell.detailLabel.textColor = TokenColors.Text.secondary
            case .proII:
                cell.detailLabel.text = "Pro II"
                cell.detailLabel.textColor = TokenColors.Text.secondary
            case .proIII:
                cell.detailLabel.text = "Pro III"
                cell.detailLabel.textColor = TokenColors.Text.secondary
            case .lite:
                cell.detailLabel.text = Strings.Localizable.proLite
                cell.detailLabel.textColor = TokenColors.Text.secondary
            case .business:
                if MEGASdk.shared.businessStatus == .active {
                    cell.detailLabel.text = Strings.Localizable.active
                } else {
                    cell.detailLabel.text = Strings.Localizable.paymentOverdue
                }
                cell.detailLabel.textColor = TokenColors.Text.secondary
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
            
            if MEGASdk.shared.isMasterBusinessAccount {
                cell.detailLabel.text = Strings.Localizable.administrator
            } else {
                cell.detailLabel.text = Strings.Localizable.user
            }
            cell.detailLabel.textColor = TokenColors.Text.secondary
            cell.nameLabel.text = Strings.Localizable.role.replacingOccurrences(of: ":", with: "")
            cell.accessoryType = .none
            return cell
        case .logout:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutID", for: indexPath) as! LogoutTableViewCell
            cell.logoutLabel.text = Strings.Localizable.logoutLabel
            cell.logoutLabel.textColor = TokenColors.Text.error
            return cell
        case .cancelSubscription:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CancelSubscriptionView", for: indexPath) as? HostingTableViewCell<CancelSubscriptionView> else {
                return HostingTableViewCell<CancelSubscriptionView>()
            }
            
            let cellView = CancelSubscriptionView(textColor: TokenColors.Text.error)
            cell.host(cellView, parent: parent)
            cell.selectionStyle = .none
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
