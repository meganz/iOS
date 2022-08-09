 extension UIAlertController {
    @objc class func inAppPurchaseAlertWithAppStoreSettingsButton(_ alertTitle: String, alertMessage: String?) -> UIAlertController {
        let alertController: UIAlertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        let appStoreSettingsAlertAction = UIAlertAction(title: Strings.Localizable.InAppPurchase.Error.Alert.primaryButtonTitle, style: .default, handler: { UIAlertAction in
            UIApplication.openAppStoreSettings()
        })
        alertController.addAction(appStoreSettingsAlertAction)
        
        let cancelAlertAction = UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAlertAction)
        
        return alertController
    }
 }
