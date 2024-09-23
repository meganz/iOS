import MEGADomain
import MEGASwift

protocol AccountPlanPurchaseUpdatesProviderProtocol: Sendable {
    /// Plan purchase updates from `MEGAPurchaseDelegate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call purchase.purchaseDelegateMutableArray.add on creation and  purchase.purchaseDelegateMutableArray.remove onTermination of `AsyncStream`.
    /// It will yield `Result<Void, AccountPlanErrorEntity>` until sequence terminated
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> { get }
    
    /// Restore purchase updates from `MEGARestoreDelegate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call purchase.restoreDelegateMutableArray.add on creation and  purchase.restoreDelegateMutableArray.remove onTermination of `AsyncStream`.
    /// It will yield `RestorePurchaseStateEntity` until sequence terminated
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> { get }
}

struct AccountPlanPurchaseUpdatesProvider: AccountPlanPurchaseUpdatesProviderProtocol {
    private let purchase: MEGAPurchase
    
    init(purchase: MEGAPurchase) {
        self.purchase = purchase
    }
    
    var purchasePlanResultUpdates: AnyAsyncSequence<Result<Void, AccountPlanErrorEntity>> {
        AsyncStream { continuation in
            let delegate = PurchaseDelegate(purchasePlanResultUpdate: { result in
                continuation.yield(result)
            })
            
            continuation.onTermination = { _ in
                purchase.purchaseDelegateMutableArray.remove(delegate)
            }
            purchase.purchaseDelegateMutableArray.add(delegate)
        }
        .eraseToAnyAsyncSequence()
    }
    
    var restorePurchaseUpdates: AnyAsyncSequence<RestorePurchaseStateEntity> {
        AsyncStream { continuation in
            let delegate = PurchaseDelegate(restoreResultUpdate: { result in
                continuation.yield(result)
            })
            
            continuation.onTermination = { _ in
                purchase.restoreDelegateMutableArray.remove(delegate)
            }
            purchase.restoreDelegateMutableArray.add(delegate)
        }
        .eraseToAnyAsyncSequence()
    }
}

// MARK: - AccountRequestDelegate
private final class PurchaseDelegate: NSObject {
    var purchasePlanResultUpdate: (Result<Void, AccountPlanErrorEntity>) -> Void
    var restoreResultUpdate: (RestorePurchaseStateEntity) -> Void
    
    init(
        purchasePlanResultUpdate: @escaping (Result<Void, AccountPlanErrorEntity>) -> Void = {_ in},
        restoreResultUpdate: @escaping (RestorePurchaseStateEntity) -> Void = {_ in}
    ) {
        self.purchasePlanResultUpdate = purchasePlanResultUpdate
        self.restoreResultUpdate = restoreResultUpdate
    }
}

// MARK: - MEGARequestDelegate
extension PurchaseDelegate: MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase) {
        purchasePlanResultUpdate(.success)
    }
    
    func failedPurchase(_ errorCode: Int, message errorMessage: String!) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        purchasePlanResultUpdate(.failure(error))
    }
}

// MARK: - MEGARestoreDelegate
extension PurchaseDelegate: MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase) {
        restoreResultUpdate(.success)
    }
    
    func incompleteRestore() {
        restoreResultUpdate(.incomplete)
    }
    
    func failedRestore(_ errorCode: Int, message errorMessage: String!) {
        let error = AccountPlanErrorEntity(errorCode: errorCode, errorMessage: errorMessage)
        restoreResultUpdate(.failed(error))
    }
}
