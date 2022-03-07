extension ConfirmAccountViewController {
    @objc func showSubscriptionDialogIfNeeded() {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails,
              accountDetails.type != .free else {
                  return
              }
        
        switch accountDetails.subscriptionMethodId {
        case .itunes:
            if #available(iOS 15.0, *) {
                showSubscriptionDialog(
                    message: Strings.Localizable.Account.Delete.Subscription.Itunes.withoutManage,
                    additionalOptionTitle: Strings.Localizable.manage) {
                        UIApplication.openAppleIDSubscriptionsPage()
                    }
            } else {
                showSubscriptionDialog(message: Strings.Localizable.Account.Delete.Subscription.Itunes.withoutManage)
            }
            
        case .googleWallet:
            showSubscriptionDialog(
                message: Strings.Localizable.Account.Delete.Subscription.googlePlay,
                additionalOptionTitle: Strings.Localizable.Account.Delete.Subscription.GooglePlay.visit) {
                    if let url = NSURL(string: "https://play.google.com/store/account/subscriptions") {
                        url.mnz_presentSafariViewController()
                    }
                }
            
        case .huaweiWallet:
            showSubscriptionDialog(
                message: Strings.Localizable.Account.Delete.Subscription.huaweiAppGallery,
                additionalOptionTitle: Strings.Localizable.Account.Delete.Subscription.HuaweiAppGallery.visit) {
                    if let url = NSURL(string: "https://consumer.huawei.com/en/mobileservices/") {
                        url.mnz_presentSafariViewController()
                    }
                }
            
        case .stripe2, .ECP:
            showSubscriptionDialog(message: Strings.Localizable.Account.Delete.Subscription.stripeOrEcp)
            
        default:
            return
        }
    }

    private func showSubscriptionDialog(message: String,
                                        additionalOptionTitle: String? = nil,
                                        additionalOptionHander: (() -> Void)? = nil) {
        
        let alertController = UIAlertController(
            title: Strings.Localizable.Account.Delete.Subscription.title,
            message: message,
            preferredStyle: .alert)
        
        if let additionalOption = additionalOptionTitle {
            alertController.addAction(
                UIAlertAction(title: additionalOption,
                              style: .default) { _ in
                                  additionalOptionHander?()
                              }
            )
        }

        alertController.addAction(
            UIAlertAction(title: Strings.Localizable.ok,
                          style: .default,
                          handler: nil)
        )
        
        present(alertController, animated: true, completion: nil)
    }
}
