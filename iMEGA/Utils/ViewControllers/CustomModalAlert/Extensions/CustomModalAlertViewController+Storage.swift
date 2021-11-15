import Foundation

extension CustomModalAlertViewController {
    func configureForStorageEvent(_ event: MEGAEvent) {
        let imageName = event.number == StorageState.orange.rawValue ? "storage_almost_full" : "storage_full"
        
        let title = event.number == StorageState.orange.rawValue ? NSLocalizedString("upgradeAccount", comment: "Button title which triggers the action to upgrade your MEGA account level") : NSLocalizedString("dialog.storage.odq.title", comment: "")
        
        var detailText = event.number == StorageState.orange.rawValue ? NSLocalizedString("dialog.storage.almostFull.detail", comment: "") : NSLocalizedString("dialog.storage.odq.detail", comment: "")
        let pricing: MEGAPricing = (MEGAPurchase.sharedInstance().pricing != nil) ? MEGAPurchase.sharedInstance().pricing : MEGAPricing()
        let maxStorage = String(format: "%ld", pricing.storageGB(atProductIndex: 7))
        let maxStorageTB = String(format: "%ld", pricing.storageGB(atProductIndex: 7) / 1024)
        detailText = String(format: detailText, maxStorageTB, maxStorage)
        
        configureUpgradeAccountThreeButtons(title, detailText, nil, imageName)
    }
    
    func configureForStorageQuotaError(_ uploading: Bool) {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
            return
        }
        let imageName = accountDetails.storageMax.int64Value > accountDetails.storageUsed.int64Value ? "storage_almost_full" : "storage_full"
        
        let title = NSLocalizedString("upgradeAccount", comment: "Button title which triggers the action to upgrade your MEGA account level")
        let detailText = uploading ? NSLocalizedString("Your upload(s) cannot proceed because your account is full", comment: "uploads over storage quota warning dialog title") : NSLocalizedString("This action can not be completed as it would take you over your current storage limit", comment: "Error message shown to user when a copy/import operation would take them over their storage limit.")
        
        configureUpgradeAccountThreeButtons(title, detailText, nil, imageName)
    }
    
    func configureForStorageDownloadQuotaError() {
        let imageName = "transfer-quota-empty"
        let title = NSLocalizedString("depletedTransferQuota_title", comment: "Title shown when you almost had used your available transfer quota.")
        let detailText = NSLocalizedString("depletedTransferQuota_message", comment: "Description shown when you almost had used your available transfer quota.")
        let base64Handle = MEGASdk.base64Handle(forUserHandle: (MEGASdkManager.sharedMEGASdk().myUser?.handle)!)
        
        configureUpgradeAccountThreeButtons(title, detailText, base64Handle, imageName, hasBonusButton: false)
    }
}
