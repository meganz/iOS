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
        do {
            return try canProcessStorePayment(for: product)
        } catch {
            guard let error = error as? InAppPurchaseStoreError else { return false }
            if error == .noLoggedInUser {
                // Defer until user has logged in, save the product and return false
                savePendingPromotedProduct(product)
            }
            
            showStoreErrorMessage(error)
            return false
        }
    }
    
    @objc func processAnyPendingPromotedPlanPayment() {
        guard let pendingProduct = pendingPromotedProductForPayment() else { return }
        
        // Continuing a previously deferred payment
        MEGALogInfo("[StoreKit] Deferred promoted plan \(pendingProduct.localizedTitle) will resume purchase.")
        purchaseProduct(pendingProduct)
    }
    
    // MARK: Helpers
    private func canProcessStorePayment(for product: SKProduct) throws -> Bool {
        guard isUserLoggedIn() else {
            MEGALogInfo("[StoreKit] Defer promoted plan \(product.productIdentifier). Purchase will continue after login.")
            throw InAppPurchaseStoreError.noLoggedInUser
        }
        
        guard try !isProFlexiOrBusinessAccount() else {
            MEGALogInfo("[StoreKit] Cancel promoted plan purchase for \(product.productIdentifier). User's current account is either Pro Flexi or Business account.")
            throw InAppPurchaseStoreError.proFlexiOrBusinessAccount
        }
        
        guard try !isProductAlreadyPurchased(product) else {
            MEGALogInfo("[StoreKit] Cancel promoted plan purchase. Plan \(product.productIdentifier) is already purchased.")
            throw InAppPurchaseStoreError.alreadyPurchasedPlan
        }
        
        MEGALogInfo("[StoreKit] Start promoted plan purchase for \(product.productIdentifier).")
        return true
    }
    
    private func accountDetails() throws -> AccountDetailsEntity {
        guard let accountDetails = MEGASdk.shared.mnz_accountDetails?.toAccountDetailsEntity() else {
            throw InAppPurchaseStoreError.noAccountDetails
        }
        return accountDetails
    }
    
    private func isUserLoggedIn() -> Bool {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        return accountUseCase.isLoggedIn()
    }
    
    private func isProFlexiOrBusinessAccount() throws -> Bool {
        let accountDetails = try accountDetails()
        return accountDetails.proLevel == .proFlexi || accountDetails.proLevel == .business
    }
    
    private func isProductAlreadyPurchased(_ product: SKProduct) throws -> Bool {
        let accountDetails = try accountDetails()
        let plan = product.toAccountPlanEntity()
        return plan.type == accountDetails.proLevel && plan.subscriptionCycle == accountDetails.subscriptionCycle
    }
    
    private func showStoreErrorMessage(_ error: InAppPurchaseStoreError) {
        switch error {
        case .alreadyPurchasedPlan:
            SVProgressHUD.showError(withStatus: Strings.Localizable.UpgradeAccountPlan.Selection.Message.alreadyHaveRecurringSubscriptionOfPlan)
        case .noLoggedInUser:
            SVProgressHUD.showError(withStatus: Strings.Localizable.pleaseLogInToYourAccount)
        case .proFlexiOrBusinessAccount:
            SVProgressHUD.showError(withStatus: Strings.Localizable.Account.Upgrade.NotAvailableWithCurrentPlan.message)
        default:
            SVProgressHUD.showError(withStatus: Strings.Localizable.somethingWentWrong)
        }
    }
}
