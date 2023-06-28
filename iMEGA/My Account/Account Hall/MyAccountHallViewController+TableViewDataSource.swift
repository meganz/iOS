import MEGASwiftUI

@objc enum MyAccountSection: Int, CaseIterable {
    case mega = 0, other
}

@objc enum MyAccountMegaSection: Int, CaseIterable {
    case plan = 0, storage, contacts, backups, notifications, achievements, transfers, deviceCenter, offline, rubbishBin
}

@objc enum MyAccountOtherSection: Int, CaseIterable {
    case settings
}

extension MyAccountHallViewController: UITableViewDataSource {
    // MARK: - Settings row setup data
    private func settingsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.settingsTitle,
                              icon: Asset.Images.MyAccount.iconSettings.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Storage row setup data for Business and Pro Flexi accounts
    private func storageBusinessAccountSetupData() -> MyAccountHallCellData {
        let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails
        return MyAccountHallCellData(sectionText: Strings.Localizable.storage,
                                     storageText: Strings.Localizable.storage,
                                     transferText: Strings.Localizable.transfer,
                                     storageUsedText: NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageUsed.int64Value ?? 0)),
                                     transferUsedText: NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.transferOwnUsed.int64Value ?? 0)))
    }
    
    // MARK: - Storage row setup data
    private func storageSetupData() -> MyAccountHallCellData {
        let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails
        let detailText = String(format: "%@ / %@",
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageUsed.int64Value ?? 0)),
                                NSString.mnz_formatString(fromByteCountFormatter: String.memoryStyleString(fromByteCount: accountDetails?.storageMax.int64Value ?? 0)))
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.storage,
                                     detailText: detailText,
                                     icon: Asset.Images.MyAccount.iconStorage.image.imageFlippedForRightToLeftLayoutDirection())
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
                                     icon: Asset.Images.MyAccount.iconContacts.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: isPendingViewVisible,
                                     pendingText: pendingText)
    }
    
    // MARK: - Notifications row setup data
    private func notificationsSetupData(existsPendingView: Bool) -> MyAccountHallCellData {
        var isPendingViewVisible = false
        var pendingText = ""
        
        let unseenUserAlerts = viewModel.relevantUnseenUserAlertsCount
        
        if existsPendingView && unseenUserAlerts != 0 {
            isPendingViewVisible = true
            pendingText = String(describing: unseenUserAlerts)
        }
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.notifications,
                                     icon: Asset.Images.MyAccount.iconNotifications.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: isPendingViewVisible,
                                     pendingText: pendingText)
    }
    
    // MARK: - Backups row setup data
    private func makeBackupsCellData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.Backups.title,
                              icon: Asset.Images.MyAccount.backups.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Achievements row setup data
    private func achievementsSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.achievementsTitle,
                              icon: Asset.Images.MyAccount.iconAchievements.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Transfers row setup data
    private func transfersSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.transfers,
                              icon: Asset.Images.MyAccount.iconTransfers.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Device center row setup data
    private func makeDeviceCenterCellData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.Device.Center.title,
                              icon: Asset.Images.Backup.deviceCenter.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Offline row setup data
    private func offlineSetupData() -> MyAccountHallCellData {
        MyAccountHallCellData(sectionText: Strings.Localizable.offline,
                              icon: Asset.Images.MyAccount.iconOffline.image.imageFlippedForRightToLeftLayoutDirection(),
                              isPendingViewVisible: true)
    }
    
    // MARK: - Rubbish Bin row setup data
    private func rubbishBinSetupData() -> MyAccountHallCellData {
        var rubbishBinSize = ""
        if let rubbishBinNode = MEGASdkManager.sharedMEGASdk().rubbishNode {
            rubbishBinSize = NSString.mnz_formatString(fromByteCountFormatter: Helper.size(for: rubbishBinNode, api: MEGASdkManager.sharedMEGASdk()))
        }
        
        return MyAccountHallCellData(sectionText: Strings.Localizable.rubbishBinLabel,
                                     detailText: rubbishBinSize,
                                     icon: Asset.Images.NodeActions.rubbishBin.image.imageFlippedForRightToLeftLayoutDirection(),
                                     isPendingViewVisible: true)
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
        section == MyAccountSection.mega.rawValue ? MyAccountMegaSection.allCases.count : MyAccountOtherSection.allCases.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == MyAccountSection.mega.rawValue &&
            indexPath.row == MyAccountMegaSection.plan.rawValue &&
            isNewUpgradeAccountPlanFeatureFlagEnabled() && showPlanRow {
            return upgradePlanSetupCell(indexPath)
        }
        
        let isShowStorageUsageCell = (MEGASdk.shared.isAccountType(.business) ||
                                      MEGASdk.shared.isAccountType(.proFlexi)) &&
                                    indexPath.row == MyAccountMegaSection.storage.rawValue &&
                                    indexPath.section == MyAccountSection.mega.rawValue
        
        let identifier = isShowStorageUsageCell ? "MyAccountHallStorageUsageTableViewCellID" : "MyAccountHallTableViewCellID"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MyAccountHallTableViewCell ?? MyAccountHallTableViewCell(style: .default, reuseIdentifier: identifier)
        
        if indexPath.section == MyAccountSection.other.rawValue {
            cell.setup(data: settingsSetupData())
            return cell
        }
        
        switch MyAccountMegaSection(rawValue: indexPath.row) {
        case .storage: cell.setup(data: isShowStorageUsageCell ? storageBusinessAccountSetupData() : storageSetupData())
        case .contacts: cell.setup(data: contactsSetupData(existsPendingView: cell.pendingView != nil))
        case .backups: cell.setup(data: makeBackupsCellData())
        case .notifications: cell.setup(data: notificationsSetupData(existsPendingView: cell.pendingView != nil))
        case .achievements: cell.setup(data: achievementsSetupData())
        case .transfers: cell.setup(data: transfersSetupData())
        case .deviceCenter: cell.setup(data: makeDeviceCenterCellData())
        case .offline: cell.setup(data: offlineSetupData())
        case .rubbishBin: cell.setup(data: rubbishBinSetupData())
        default: break
        }
        
        cell.sectionLabel.sizeToFit()
        return cell
    }
}
