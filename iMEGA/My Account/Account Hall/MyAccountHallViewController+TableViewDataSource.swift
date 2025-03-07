import Accounts
import MEGAL10n
import MEGASwiftUI

extension MyAccountHallViewController: UITableViewDataSource {
    // MARK: - Settings row setup data
    private func settingsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.settingsTitle,
                              icon: UIImage.iconSettings.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Storage row setup data for Business and Pro Flexi accounts
    private func storageBusinessAccountSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(
            sectionText: Strings.Localizable.storage,
            storageText: Strings.Localizable.storage,
            transferText: Strings.Localizable.transfer,
            storageUsedText: NSString.mnz_formatString(
                fromByteCountFormatter: String.memoryStyleString(
                    fromByteCount: viewModel.storageUsed
                )
            ),
            transferUsedText: NSString.mnz_formatString(
                fromByteCountFormatter: String.memoryStyleString(fromByteCount: viewModel.transferUsed)
            )
        )
    }
    
    // MARK: - Storage row setup data
    private func storageSetupData() -> MyAccountHallCellData {
        let detailText = String(format: "%@ / %@",
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: viewModel.storageUsed)),
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: viewModel.storageMax)))
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.storage,
                                     detailText: detailText,
                                     icon: UIImage.iconStorage.imageFlippedForRightToLeftLayoutDirection(),
                                     showLoadingIndicator: viewModel.isAccountUpdating)
    }
    
    // MARK: - My Account row setup data
    private func myAccountSetupCell(_ indexPath: IndexPath) -> HostingTableViewCell<MyAccountHallMenuView> {
        guard let cell = tableView?.dequeueReusableCell(withIdentifier: "MyAccountHallMenuView", for: indexPath) as? HostingTableViewCell<MyAccountHallMenuView> else {
            return HostingTableViewCell<MyAccountHallMenuView>()
        }
        
        let menu = MyAccountHallCellData(sectionText: Strings.Localizable.Account.MyAccount.title,
                                         icon: UIImage.myAccount.imageFlippedForRightToLeftLayoutDirection(),
                                         disclosureIndicatorIcon: UIImage.standardDisclosureIndicator)
        let cellView = MyAccountHallMenuView(menuDetails: menu)
        cell.host(cellView, parent: self)
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - Contacts row setup data
    private func contactsSetupData(existsPendingView: Bool) -> MyAccountHallCellData {
        var isPendingViewVisible = false
        var pendingText = ""
        let incomingContacts = viewModel.incomingContactRequestsCount
        
        if existsPendingView && incomingContacts != 0 {
            isPendingViewVisible = true
            pendingText = String(describing: incomingContacts)
        }
        return MyAccountHallCellData(sectionText: Strings.Localizable.contactsTitle,
                                     icon: UIImage.iconContacts.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: isPendingViewVisible,
                                     pendingText: pendingText)
    }
    
    // MARK: - Notifications row setup data
    private func notificationsSetupData(existsPendingView: Bool, existsPromoView: Bool) -> MyAccountHallCellData {
        var isPendingViewVisible = false
        var pendingText = ""
        var promoText: String?
        
        let unreadCount = Int(viewModel.relevantUnseenUserAlertsCount) + viewModel.unreadNotificationsCount
        
        if existsPendingView && unreadCount != 0 {
            isPendingViewVisible = true
            pendingText = String(describing: unreadCount)
        }
        
        if existsPromoView && viewModel.arePromosAvailable {
            promoText = Strings.Localizable.Notifications.Tag.Promo.title
        }
        
        return MyAccountHallCellData(
            sectionText: Strings.Localizable.notifications,
            icon: UIImage.iconNotifications.imageFlippedForRightToLeftLayoutDirection(),
            isPendingViewVisible: isPendingViewVisible,
            pendingText: pendingText,
            promoText: promoText
        )
    }
    
    // MARK: - Achievements row setup data
    private func achievementsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.achievementsTitle,
                              icon: UIImage.iconAchievements.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Transfers row setup data
    private func transfersSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.transfers,
                              icon: UIImage.iconTransfers.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Device center row setup data
    private func makeDeviceCenterCellData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.Device.Center.title,
                              icon: UIImage.deviceCenter.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Offline row setup data
    private func offlineSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.offline,
                              icon: UIImage.iconOffline.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Rubbish Bin row setup data
    private func rubbishBinSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(
            sectionText: Strings.Localizable.rubbishBinLabel,
            detailText: viewModel.rubbishBinFormattedStorageUsed,
            icon: UIImage.rubbishBin.imageFlippedForRightToLeftLayoutDirection(),
            isPendingViewVisible: true
        )
    }
    
    // MARK: - Upgrade Plan row setup
    private func upgradePlanSetupCell(_ indexPath: IndexPath) -> HostingTableViewCell<MyAccountHallPlanView> {
        guard let cell = tableView?.dequeueReusableCell(withIdentifier: "AccountPlanUpgradeCell", for: indexPath) as? HostingTableViewCell<MyAccountHallPlanView> else {
            return HostingTableViewCell<MyAccountHallPlanView>()
        }
        
        let upgradeCellView = MyAccountHallPlanView(viewModel: self.viewModel)
        cell.host(upgradeCellView, parent: self)
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - UITableView data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        MyAccountSection.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MyAccountMegaSection.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == MyAccountSection.mega.rawValue {
            switch indexPath.row {
            case MyAccountMegaSection.plan.rawValue:
                if viewModel.showPlanRow {
                    return upgradePlanSetupCell(indexPath)
                }
            case MyAccountMegaSection.myAccount.rawValue:
                return myAccountSetupCell(indexPath)
            default:
                break
            }
        }
        
        let isShowStorageUsageCell = (viewModel.isBusinessAccount ||
                                      viewModel.isProFlexiAccount) &&
                                    indexPath.row == MyAccountMegaSection.storage.rawValue &&
                                    indexPath.section == MyAccountSection.mega.rawValue
        
        let identifier = isShowStorageUsageCell ? "MyAccountHallStorageUsageTableViewCellID" : "MyAccountHallTableViewCellID"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MyAccountHallTableViewCell ?? MyAccountHallTableViewCell(style: .default, reuseIdentifier: identifier)
        
        switch MyAccountMegaSection(rawValue: indexPath.row) {
        case .storage: cell.setup(data: isShowStorageUsageCell ? storageBusinessAccountSetupData() : storageSetupData())
        case .contacts: cell.setup(data: contactsSetupData(existsPendingView: cell.pendingView != nil))
        case .notifications: cell.setup(data: notificationsSetupData(existsPendingView: cell.pendingView != nil, existsPromoView: cell.promoView != nil))
        case .achievements: cell.setup(data: achievementsSetupData())
        case .transfers: cell.setup(data: transfersSetupData())
        case .deviceCenter: cell.setup(data: makeDeviceCenterCellData())
        case .offline: cell.setup(data: offlineSetupData())
        case .rubbishBin: cell.setup(data: rubbishBinSetupData())
        case .settings: cell.setup(data: settingsSetupData())
        default: break
        }
        
        cell.sectionLabel.sizeToFit()
        return cell
    }
}
