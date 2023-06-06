
extension MyAccountHallViewController: UITableViewDelegate {
    
    public var showPlanRow: Bool {
        !MEGASdk.shared.isAccountType(.business) && !MEGASdk.shared.isAccountType(.proFlexi)
    }
    
    private func calculateCellHeight(at indexPath: IndexPath) -> CGFloat {
        guard indexPath.section != MyAccountSection.other.rawValue else {
            return UITableView.automaticDimension
        }
        
        var shouldShowCell = true
        switch MyAccountMegaSection(rawValue: indexPath.row) {
        case .plan:
            shouldShowCell = isNewUpgradeAccountPlanFeatureFlagEnabled() && showPlanRow
        case .achievements:
            shouldShowCell = MEGASdk.shared.isAchievementsEnabled
        case .backups:
            shouldShowCell = isBackupSectionVisible
        default: break
        }
        
        return shouldShowCell ? UITableView.automaticDimension : 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        calculateCellHeight(at: indexPath)
    }
    
    //To remove the space between the table view and the profile view or the add phone number view
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0.01
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == MyAccountSection.other.rawValue {
            showSettings()
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        switch indexPath.row {
        case MyAccountMegaSection.storage.rawValue:
            if MEGASdk.shared.mnz_accountDetails != nil {
                let usageVC = UIStoryboard(name: "Usage", bundle: nil).instantiateViewController(withIdentifier: "UsageViewControllerID")
                navigationController?.pushViewController(usageVC, animated: true)
            } else {
                MEGALogError("Account details unavailable")
            }
            
        case MyAccountMegaSection.notifications.rawValue:
            let notificationsTVC = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsTableViewControllerID")
            navigationController?.pushViewController(notificationsTVC, animated: true)
            
        case MyAccountMegaSection.contacts.rawValue:
            let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID")
            navigationController?.pushViewController(contactsVC, animated: true)
            
        case MyAccountMegaSection.backups.rawValue:
            navigateToBackups()
            
        case MyAccountMegaSection.achievements.rawValue:
            let achievementsVC = UIStoryboard(name: "Achievements", bundle: nil).instantiateViewController(withIdentifier: "AchievementsViewControllerID")
            navigationController?.pushViewController(achievementsVC, animated: true)
            
        case MyAccountMegaSection.transfers.rawValue:
            let transferVC = UIStoryboard(name: "Transfers", bundle: nil).instantiateViewController(withIdentifier: "TransfersWidgetViewControllerID")
            navigationController?.pushViewController(transferVC, animated: true)
            
        case MyAccountMegaSection.offline.rawValue:
            let offlineVC = UIStoryboard(name: "Offline", bundle: nil).instantiateViewController(withIdentifier: "OfflineViewControllerID")
            navigationController?.pushViewController(offlineVC, animated: true)
            
        case MyAccountMegaSection.rubbishBin.rawValue:
            guard let cloudDriveVC = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "CloudDriveID") as? CloudDriveViewController, let rubbishNode = MEGASdk.shared.rubbishNode else { return }
            cloudDriveVC.parentNode = rubbishNode
            cloudDriveVC.displayMode = .rubbishBin
            navigationController?.pushViewController(cloudDriveVC, animated: true)
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
