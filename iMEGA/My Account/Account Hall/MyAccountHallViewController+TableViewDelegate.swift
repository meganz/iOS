import MEGAAppSDKRepo
import MEGADomain

extension MyAccountHallViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.calculateCellHeight(at: indexPath)
    }
    
    // To remove the space between the table view and the profile view or the add phone number view
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        0.01
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case MyAccountMegaSection.storage.rawValue:
            guard viewModel.accountDetails != nil else {
                MEGALogError("[Account Hall] Account details unavailable")
                return
            }
            showUsageView()
            
        case MyAccountMegaSection.myAccount.rawValue:
            viewModel.dispatch(.didTapMyAccountButton)
            showProfileView()
            
        case MyAccountMegaSection.notifications.rawValue:
            viewModel.dispatch(.didTapNotificationCentre)
            
        case MyAccountMegaSection.contacts.rawValue:
            let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID")
            navigationController?.pushViewController(contactsVC, animated: true)
            
        case MyAccountMegaSection.achievements.rawValue:
            let achievementsVC = UIStoryboard(name: "Achievements", bundle: nil).instantiateViewController(withIdentifier: "AchievementsViewControllerID")
            navigationController?.pushViewController(achievementsVC, animated: true)
            
        case MyAccountMegaSection.transfers.rawValue:
            let transferVC = TransfersWidgetViewController.sharedTransfer()
            transferVC.navigationItem.leftBarButtonItem = nil
            CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers widget from MyAccountHall")
            navigationController?.pushViewController(transferVC, animated: true)
            
        case MyAccountMegaSection.deviceCenter.rawValue:
            viewModel.dispatch(.didTapDeviceCenterButton)
            
        case MyAccountMegaSection.offline.rawValue:
            let offlineVC = UIStoryboard(name: "Offline", bundle: nil).instantiateViewController(withIdentifier: "OfflineViewControllerID")
            navigationController?.pushViewController(offlineVC, animated: true)
            
        case MyAccountMegaSection.rubbishBin.rawValue:
            
            guard 
                let rubbishNode = MEGASdk.shared.rubbishNode,
                let nc = navigationController
            else { return }
            
            let factory = CloudDriveViewControllerFactory.make(nc: nc)
            let cloudDriveVC = factory.buildBare(
                parentNode: rubbishNode.toNodeEntity(),
                config: .init(displayMode: .rubbishBin)
            )
            if let cloudDriveVC {
                navigationController?.pushViewController(cloudDriveVC, animated: true)
            }
            
        case MyAccountMegaSection.settings.rawValue:
            showSettings()
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
