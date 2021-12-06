import Foundation

extension CustomModalAlertViewController {
    func configureForStorageEvent(_ event: MEGAEvent) {
        let imageName = event.number == StorageState.orange.rawValue ? Asset.Images.WarningStorageAlmostFull.storageAlmostFull.name : Asset.Images.WarningStorageAlmostFull.storageFull.name
        
        let title = event.number == StorageState.orange.rawValue ? Strings.Localizable.upgradeAccount : Strings.Localizable.Dialog.Storage.Odq.title

        let pricing: MEGAPricing = (MEGAPurchase.sharedInstance().pricing != nil) ? MEGAPurchase.sharedInstance().pricing : MEGAPricing()
        let maxStorage = String(format: "%ld", pricing.storageGB(atProductIndex: 7))
        let maxStorageTB = String(format: "%ld", pricing.storageGB(atProductIndex: 7) / 1024)
        
        let detailText = event.number == StorageState.orange.rawValue ? Strings.Localizable.Dialog.Storage.AlmostFull.detail(maxStorageTB, maxStorage) : Strings.Localizable.Dialog.Storage.Odq.detail
        
        configureUpgradeAccountThreeButtons(title, detailText, nil, imageName)
    }
    
    func configureForStorageQuotaError(_ uploading: Bool) {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else {
            return
        }
        let imageName = accountDetails.storageMax.int64Value > accountDetails.storageUsed.int64Value ? Asset.Images.WarningStorageAlmostFull.storageAlmostFull.name : Asset.Images.WarningStorageAlmostFull.storageFull.name
        
        let title = Strings.Localizable.upgradeAccount
        let detailText = uploading ? Strings.Localizable.yourUploadSCannotProceedBecauseYourAccountIsFull : Strings.Localizable.thisActionCanNotBeCompletedAsItWouldTakeYouOverYourCurrentStorageLimit
        
        configureUpgradeAccountThreeButtons(title, detailText, nil, imageName)
    }
    
    func configureForStorageDownloadQuotaError() {
        let imageName = Asset.Images.WarningTransferQuota.transferQuotaEmpty.name
        let title = Strings.Localizable.depletedTransferQuotaTitle
        let detailText = Strings.Localizable.depletedTransferQuotaMessage
        let base64Handle = MEGASdk.base64Handle(forUserHandle: MEGASdkManager.sharedMEGASdk().myUser?.handle ?? MEGAInvalidHandle)
        
        configureUpgradeAccountThreeButtons(title, detailText, base64Handle, imageName, hasBonusButton: false)
    }
}
