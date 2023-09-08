import MEGADomain
import MEGAL10n

extension MEGAPurchase {
    private enum InAppPurchaseStoreError: Error {
        case alreadyPurchasedPlan
        case noLoggedInUser
        case noAccountDetails
        case proFlexiOrBusinessAccount
    }
    
    // MARK: - Promoted plan purchase
    @objc func shouldAddStorePayment(for product: SKProduct) -> Bool {
        SVProgressHUD.show()
        do {
            return try canProcessStorePayment(for: product)
        } catch {
            guard let error = error as? InAppPurchaseStoreError else {
                SVProgressHUD.dismiss()
                return false
            }
            
            if error == .noLoggedInUser {
                // Defer until user has logged in, save the product and return false
                savePendingPromotedProduct(product)
            } else if error == .noAccountDetails {
                // Defer until the account details is fetched and return false
                fetchAccountDetailsToPurchaseProduct(product)
                return false
            }
            
            SVProgressHUD.dismiss()
            showStoreErrorMessage(error)
            return false
        }
    }
    
    @objc func processAnyPendingPromotedPlanPayment() {
        guard let pendingProduct = pendingPromotedProductForPayment() else { return }
        
        // Check if payment can still resume
        guard shouldAddStorePayment(for: pendingProduct) else { return }
        
        // Continuing a previously deferred payment
        MEGALogInfo("[StoreKit] Deferred promoted plan \(pendingProduct.localizedTitle) will resume purchase.")
        purchaseProduct(pendingProduct)
    }
    
    // MARK: Helpers
    private func canProcessStorePayment(for product: SKProduct) throws -> Bool {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        
        guard accountUseCase.isLoggedIn() else {
            MEGALogInfo("[StoreKit] Defer promoted plan \(product.productIdentifier). Purchase will continue after login.")
            throw InAppPurchaseStoreError.noLoggedInUser
        }
        
        guard let accountDetails = accountUseCase.currentAccountDetails else {
            MEGALogInfo("[StoreKit] No current account details")
            throw InAppPurchaseStoreError.noAccountDetails
        }
        
        let isProFlexiOrBusinessAccount = accountDetails.proLevel == .proFlexi ||
                                            accountDetails.proLevel == .business
        guard !isProFlexiOrBusinessAccount else {
            MEGALogInfo("[StoreKit] Cancel promoted plan purchase for \(product.productIdentifier). User's current account is either Pro Flexi or Business account.")
            throw InAppPurchaseStoreError.proFlexiOrBusinessAccount
        }
        
        let plan = product.toAccountPlanEntity()
        let isProductAlreadyPurchased = plan.type == accountDetails.proLevel &&
                                        plan.subscriptionCycle == accountDetails.subscriptionCycle
        guard !isProductAlreadyPurchased else {
            MEGALogInfo("[StoreKit] Cancel promoted plan purchase. Plan \(product.productIdentifier) is already purchased.")
            throw InAppPurchaseStoreError.alreadyPurchasedPlan
        }
        
        MEGALogInfo("[StoreKit] Start promoted plan purchase for \(product.productIdentifier).")
        return true
    }
    
    private func fetchAccountDetailsToPurchaseProduct(_ product: SKProduct) {
        Task {
            do {
                let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
                _ = try await accountUseCase.refreshCurrentAccountDetails()
                
                guard shouldAddStorePayment(for: product) else { return }
                
                MEGALogInfo("[StoreKit] Deferred promoted plan \(product.localizedTitle) will resume purchase.")
                purchaseProduct(product)
            } catch {
                MEGALogError("[StoreKit] Error loading account details. Error: \(error)")
                await SVProgressHUD.dismiss()
                await SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
            }
        }
    }
    
    private func showStoreErrorMessage(_ error: InAppPurchaseStoreError) {
        switch error {
        case .alreadyPurchasedPlan:
            SVProgressHUD.showError(withStatus: Strings.Localizable.UpgradeAccountPlan.Selection.Message.alreadyHaveRecurringSubscriptionOfPlan)
        case .noLoggedInUser:
            SVProgressHUD.setErrorImage(Asset.Images.Hud.hudError.image)
            SVProgressHUD.showError(withStatus: Strings.Localizable.pleaseLogInToYourAccount)
        case .proFlexiOrBusinessAccount:
            SVProgressHUD.showError(withStatus: Strings.Localizable.Account.Upgrade.NotAvailableWithCurrentPlan.message)
        case .noAccountDetails:
            return
        }
    }
}
