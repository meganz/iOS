import MEGADesignToken
import MEGADomain

extension ProductDetailViewController {
    
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
    
    // MARK: - Token colors
    @objc var whiteTextColor: UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.onColor : UIColor.mnz_whiteFFFFFF()
    }

    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }
}
