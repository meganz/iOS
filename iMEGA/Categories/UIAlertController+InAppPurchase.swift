 extension UIAlertController {
    @objc class func inAppPurchaseAlertWithAppStoreSettingsButton(_ alertTitle: String, alertMessage: String?) -> UIAlertController {
        let alertController: UIAlertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        let appStoreSettingsAlertAction = UIAlertAction(title: NSLocalizedString("inAppPurchase.error.alert.primaryButtonTitle", comment: "Button that redirect you to the main page of your Account in the App Store"), style: .default, handler: { UIAlertAction in
            UIApplication.openAppStoreSettings()
        })
        alertController.addAction(appStoreSettingsAlertAction)
        
        let cancelAlertAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(cancelAlertAction)
        
        return alertController
    }
 }
