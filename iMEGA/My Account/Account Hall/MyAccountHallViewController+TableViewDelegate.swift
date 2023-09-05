import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGASDKRepo

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
            shouldShowCell = viewModel.isNewUpgradeAccountPlanEnabled && showPlanRow
        case .achievements:
            shouldShowCell = MEGASdk.shared.isAchievementsEnabled
        case .backups:
            shouldShowCell = isBackupSectionVisible
        case .deviceCenter:
            shouldShowCell = viewModel.isDeviceCenterEnabled()
        default: break
        }
        
        return shouldShowCell ? UITableView.automaticDimension : 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        calculateCellHeight(at: indexPath)
    }
    
    // To remove the space between the table view and the profile view or the add phone number view
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
            
        case MyAccountMegaSection.deviceCenter.rawValue:
            DeviceListViewRouter(
                navigationController: navigationController,
                deviceCenterUseCase:
                    DeviceCenterUseCase(
                        deviceCenterRepository: DeviceCenterRepository.newRepo
                    ),
                deviceCenterAssets:
                    makeDeviceListAssetData()
            ).start()
            
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
    
    private func makeDeviceListAssetData() -> DeviceCenterAssets {
        DeviceCenterAssets(
            deviceListAssets:
                DeviceListAssets(
                    title: Strings.Localizable.Device.Center.title,
                    currentDeviceTitle: Strings.Localizable.Device.Center.Current.Device.title,
                    otherDevicesTitle: Strings.Localizable.Device.Center.Other.Devices.title,
                    deviceDefaultName: Strings.Localizable.Device.Center.Default.Device.title
                ),
            backupListAssets:
                BackupListAssets(
                    backupTypes: [
                        BackupType(type: .backupUpload, iconName: Asset.Images.Backup.backupFolder.name),
                        BackupType(type: .cameraUpload, iconName: Asset.Images.Backup.cameraUploadsFolder.name),
                        BackupType(type: .mediaUpload, iconName: Asset.Images.Backup.cameraUploadsFolder.name),
                        BackupType(type: .twoWay, iconName: Asset.Images.Backup.syncFolder.name),
                        BackupType(type: .downSync, iconName: Asset.Images.Backup.syncFolder.name),
                        BackupType(type: .upSync, iconName: Asset.Images.Backup.syncFolder.name),
                        BackupType(type: .invalid, iconName: Asset.Images.Backup.syncFolder.name)
                    ]
                ),
            emptyStateAssets:
                EmptyStateAssets(
                    image: Asset.Images.EmptyStates.searchEmptyState.name,
                    title: Strings.Localizable.noResults
                ),
            searchAssets:
                SearchAssets(
                    placeHolder: Strings.Localizable.search,
                    cancelTitle: Strings.Localizable.cancel
                ),
            backupStatuses: [
                    BackupStatus(
                        status: .upToDate,
                        title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                        colorName: Colors.General.Green._34C759.name,
                        iconName: Asset.Images.BackupStatus.upToDate.name
                    ),
                    BackupStatus(
                        status: .scanning,
                        title: Strings.Localizable.Device.Center.Backup.Scanning.Status.message,
                        colorName: Colors.General.Blue._007Aff.name,
                        iconName: Asset.Images.BackupStatus.updating.name
                    ),
                    BackupStatus(
                        status: .initialising,
                        title: Strings.Localizable.Device.Center.Backup.Initialising.Status.message,
                        colorName: Colors.General.Blue._007Aff.name,
                        iconName: Asset.Images.BackupStatus.updating.name
                    ),
                    BackupStatus(
                        status: .updating,
                        title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                        colorName: Colors.General.Blue._007Aff.name,
                        iconName: Asset.Images.BackupStatus.updating.name
                    ),
                    BackupStatus(
                        status: .noCameraUploads,
                        title: Strings.Localizable.Device.Center.Backup.NoCameraUploads.Status.message,
                        colorName: Colors.General.Orange.ff9500.name,
                        iconName: Asset.Images.BackupStatus.noCameraUploads.name
                    ),
                    BackupStatus(
                        status: .disabled,
                        title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
                        colorName: Colors.General.Orange.ff9500.name,
                        iconName: Asset.Images.BackupStatus.disabled.name
                    ),
                    BackupStatus(
                        status: .offline,
                        title: Strings.Localizable.Device.Center.Backup.Offline.Status.message,
                        colorName: Colors.General.Gray._8E8E93.name,
                        iconName: Asset.Images.BackupStatus.offlineStatus.name
                    ),
                    BackupStatus(
                        status: .backupStopped,
                        title: Strings.Localizable.Device.Center.Backup.BackupStopped.Status.message,
                        colorName: Colors.General.Gray._8E8E93.name,
                        iconName: Asset.Images.BackupStatus.error.name
                    ),
                    BackupStatus(
                        status: .paused,
                        title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
                        colorName: Colors.General.Gray._8E8E93.name,
                        iconName: Asset.Images.BackupStatus.paused.name
                    ),
                    BackupStatus(
                        status: .outOfQuota,
                        title: Strings.Localizable.Device.Center.Backup.OutOfQuota.Status.message,
                        colorName: Colors.General.Red.ff3B30.name,
                        iconName: Asset.Images.BackupStatus.outOfQuota.name
                    ),
                    BackupStatus(
                        status: .error,
                        title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
                        colorName: Colors.General.Red.ff3B30.name,
                        iconName: Asset.Images.BackupStatus.error.name
                    ),
                    BackupStatus(
                        status: .blocked,
                        title: Strings.Localizable.Device.Center.Backup.Blocked.Status.message,
                        colorName: Colors.General.Red.ff3B30.name,
                        iconName: Asset.Images.BackupStatus.disabled.name
                    )
                ],
            deviceCenterActions: [
                DeviceCenterAction(
                    type: .cameraUploads,
                    title: Strings.Localizable.cameraUploadsLabel,
                    subtitle: "",
                    icon: Asset.Images.Settings.cameraUploadsSettings.name,
                    action: {
                    }
                ),
                DeviceCenterAction(
                    type: .info,
                    title: Strings.Localizable.info,
                    icon: Asset.Images.Generic.info.name,
                    action: {
                    }
                ),
                DeviceCenterAction(
                    type: .rename,
                    title: Strings.Localizable.rename,
                    icon: Asset.Images.Generic.rename.name,
                    action: {
                    }
                ),
                DeviceCenterAction(
                    type: .showInCD,
                    title: Strings.Localizable.Device.Center.Show.In.Cloud.Drive.Action.title,
                    icon: Asset.Images.ActionSheetIcons.cloudDriveFolder.name,
                    action: {
                    }
                ),
                DeviceCenterAction(
                    type: .showInBackups,
                    title: Strings.Localizable.Device.Center.Show.In.Backups.Action.title,
                    icon: Asset.Images.MyAccount.backups.name,
                    action: {
                    }
                )
            ]
        )
    }
}
