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
}
