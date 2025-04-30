import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

extension CustomModalAlertViewController {
    func configureForStorageEvent(_ event: MEGAEvent) {
        let storageStateImage = event.number == StorageState.orange.rawValue 
        ? UIImage.storageAlmostFull
        : UIImage.warningStorageFull
        
        let title = event.number == StorageState.orange.rawValue ? Strings.Localizable.upgradeAccount : Strings.Localizable.Dialog.Storage.Odq.title
        
        let detailText = storageDetailForEvent(event, pricing: MEGAPurchase.sharedInstance().pricing)
        configureUpgradeAccountThreeButtons(title, detailText, nil, storageStateImage)
        
        if MEGAPurchase.sharedInstance().pricing == nil {
            SVProgressHUD.show()
            let sdkDelegate = RequestDelegate { result in
                SVProgressHUD.dismiss()
                switch result {
                case .success(let request):
                    let pricing = request.pricing ?? MEGAPricing()
                    let detailText = self.storageDetailForEvent(event, pricing: pricing)
                    self.configureUpgradeAccountDetailText(detailText)
                default:
                    return
                }
            }
            MEGASdk.shared.getPricingWith(sdkDelegate)
        }
    }
    
    private func storageDetailForEvent(_ event: MEGAEvent, pricing: MEGAPricing?) -> String {
        let pricing = pricing ?? MEGAPricing()
        let productStorage = pricing.productStorageGB(ofAccountType: .proIII)
        
        // StorageGB can return 0 if there is no product or the given account type doesn't match on the product list.
        // Checking if it is greater than zero first to avoid negative TB storage.
        let maxTB = productStorage > 0 ? productStorage / 1024 : 0

        let maxStorageTB = String(format: "%ld", maxTB)
        
        let detailText = event.number == StorageState.orange.rawValue ? Strings.Localizable.Dialog.Storage.AlmostFull.detail(maxStorageTB) : Strings.Localizable.Dialog.Storage.Odq.detail
        return detailText
    }
    
    func configureForStorageQuotaError(_ uploading: Bool) {
        var storageStateImage: UIImage?
        if let accountDetails = MEGASdk.shared.mnz_accountDetails {
            storageStateImage = accountDetails.storageMax > accountDetails.storageUsed
            ? UIImage.storageAlmostFull
            : UIImage.warningStorageFull
        }
        
        let title = Strings.Localizable.upgradeAccount
        let detailText = uploading ? Strings.Localizable.yourUploadSCannotProceedBecauseYourAccountIsFull : Strings.Localizable.thisActionCanNotBeCompletedAsItWouldTakeYouOverYourCurrentStorageLimit
        
        configureUpgradeAccountThreeButtons(title, detailText, nil, storageStateImage)
    }
    
    func configureForStorageQuotaWillExceed(for displayMode: CustomModalAlertView.Mode.StorageQuotaWillExceedDisplayMode) {
        let title: String
        let detailText: String
        let storageStateImage: UIImage
        let analyticsEvents: CustomModalAlertViewModel.CustomModalAlertViewAnalyticEvents?
        
        switch displayMode {
        case .albumLink:
            title = Strings.Localizable.AlbumLink.ImportFailed.StorageQuotaWillExceed.Alert.title
            detailText = Strings.Localizable.AlbumLink.ImportFailed.StorageQuotaWillExceed.Alert.detail
            storageStateImage = UIImage.warningStorageFull
            analyticsEvents = .init(dialogDisplayedEventIdentifier: DIContainer.albumImportStorageOverQuotaDialogEvent,
                                    fistButtonPressedEventIdentifier: DIContainer.albumsStorageOverQuotaUpgradeAccountButtonEvent)
        }
        
        configureUpgradeAccountThreeButtons(
            title,
            detailText,
            nil,
            storageStateImage,
            hasBonusButton: false,
            firstButtonTitle: Strings.Localizable.upgrade,
            dismissTitle: Strings.Localizable.cancel,
            analyticsEvents: analyticsEvents)
    }
}
