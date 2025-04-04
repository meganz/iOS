@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

final class AccountPlanPurchaseRepository: NSObject, AccountPlanPurchaseRepositoryProtocol, Sendable {

    static var newRepo: AccountPlanPurchaseRepository {
        AccountPlanPurchaseRepository(purchase: MEGAPurchase.sharedInstance(), sdk: MEGASdk.shared)
    }
    
    private let purchase: MEGAPurchase
    private let sdk: MEGASdk
    private let currentUserSource: CurrentUserSource
    
    private let successfulRestoreSourcePublisher = PassthroughSubject<Void, Never>()
    var successfulRestorePublisher: AnyPublisher<Void, Never> {
        successfulRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let incompleteRestoreSourcePublisher = PassthroughSubject<Void, Never>()
    var incompleteRestorePublisher: AnyPublisher<Void, Never> {
        incompleteRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let failedRestoreSourcePublisher = PassthroughSubject<AccountPlanErrorEntity, Never>()
    var failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> {
        failedRestoreSourcePublisher.eraseToAnyPublisher()
    }
    
    private let purchasePlanResultSourcePublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
    var purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        purchasePlanResultSourcePublisher.eraseToAnyPublisher()
    }
    
    private let submitReceiptResultSourcePublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
    var submitReceiptResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> {
        submitReceiptResultSourcePublisher
            .eraseToAnyPublisher()
    }
    
    var monitorSubmitReceiptAfterPurchase: AnyPublisher<Bool, Never> {
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.eraseToAnyPublisher()
    }

    init(
        purchase: MEGAPurchase,
        sdk: MEGASdk,
        currentUserSource: CurrentUserSource = .shared
    ) {
        self.purchase = purchase
        self.sdk = sdk
        self.currentUserSource = currentUserSource
    }
    
    func registerRestoreDelegate() async {
        purchase.restoreDelegateMutableArray.add(self)
    }
    
    func deRegisterRestoreDelegate() async {
        purchase.restoreDelegateMutableArray.remove(self)
    }
    
    func registerPurchaseDelegate() async {
        purchase.purchaseDelegateMutableArray.add(self)
    }
    
    func deRegisterPurchaseDelegate() async {
        purchase.purchaseDelegateMutableArray.remove(self)
    }

    func restorePurchase() {
        purchase.restore()
    }
    
    @MainActor
    func purchasePlan(_ plan: PlanEntity) async {
        guard let products = purchase.products as? [SKProduct],
              let productPlan = products.first(where: { $0.productIdentifier == plan.productIdentifier }) else {
            return
        }
        purchase.purchaseProduct(productPlan)
    }
    
    func accountPlanProducts() async -> [PlanEntity] {
        guard let products = purchase.products as? [SKProduct] else { return [] }

        var accountPlans: [PlanEntity] = []
        for product in products {
            // We need to find out where the current product is listed in our `MEGAPricing instance because sometimes
            // there's a mismatch between the products listed in the SDK/API and those available in the Apple Store.
            // This discrepancy can occur when new products are added to the SDK/API but haven't been added to the Apple Store yet.
            let productIndex = purchase.pricingProductIndex(for: product)
            let plan = product.toPlanEntity(
                storage: storageGB(atProductIndex: Int(productIndex)),
                transfer: transferGB(atProductIndex: Int(productIndex))
            )
            accountPlans.append(plan)
        }
        
        return accountPlans
    }
    
    private func storageGB(atProductIndex index: Int) -> Int {
        guard let pricing = purchase.pricing else { return 0 }
        return pricing.storageGB(atProductIndex: index)
    }
    
    private func transferGB(atProductIndex index: Int) -> Int {
        guard let pricing = purchase.pricing else { return 0 }
        return pricing.transferGB(atProductIndex: index)
    }
    
    func startMonitoringSubmitReceiptAfterPurchase() {
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(purchase.isSubmittingReceipt)
    }
    
    func endMonitoringPurchaseReceipt() {
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.send(false)
    }
    
    var isSubmittingReceiptAfterPurchase: Bool {
        currentUserSource.monitorSubmitReceiptAfterPurchaseSourcePublisher.value
    }
}

// MARK: - MEGARequestDelegate
extension AccountPlanPurchaseRepository: MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase?) {
        successfulRestoreSourcePublisher.send()
    }
    
    func incompleteRestore() {
        incompleteRestoreSourcePublisher.send()
    }
    
    func failedRestore(_ errorCode: Int, message errorMessage: String!) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        failedRestoreSourcePublisher.send(error)
    }
}

// MARK: - MEGAPurchaseDelegate
extension AccountPlanPurchaseRepository: MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase?) {
        purchasePlanResultSourcePublisher.send(.success)
    }
    
    func failedPurchase(_ errorCode: Int, message errorMessage: String?) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        purchasePlanResultSourcePublisher.send(.failure(error))
    }
    
    func successSubmitReceipt() {
        submitReceiptResultSourcePublisher.send(.success)
    }
    
    func failedSubmitReceipt(_ errorCode: Int) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: nil)
        submitReceiptResultSourcePublisher.send(.failure(error))
    }
    
}
