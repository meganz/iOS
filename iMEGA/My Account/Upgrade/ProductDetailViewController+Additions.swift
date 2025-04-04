import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain

extension ProductDetailViewController {
    
    // MARK: - Token colors
    @objc var whiteTextColor: UIColor {
        TokenColors.Text.onColor
    }

    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    // MARK: - Additional functions
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
        tableView.sizeFooterToFit()
    }

    @objc func isPurchaseCancelled(errorCode: Int) -> Bool {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: nil)
        return error.toPurchaseErrorStatus() == .paymentCancelled
    }
    
    @objc func postDismissOnboardingProPlanDialog() {
        NotificationCenter.default.post(name: .dismissOnboardingProPlanDialog, object: nil)
    }
    
    @objc func cancelCreditCardSubscriptionsBeforeContinuePurchasingProduct(_ product: SKProduct) {
        Task {
            let subscriptionsUseCase = SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo)
            
            do {
                try await subscriptionsUseCase.cancelSubscriptions()
            } catch {
                MEGALogError("[Upgrade Account] Unable to cancel active subscription: \(error.localizedDescription)")
            }
            
            MEGAPurchase.sharedInstance().purchaseProduct(product)
        }
    }
}
