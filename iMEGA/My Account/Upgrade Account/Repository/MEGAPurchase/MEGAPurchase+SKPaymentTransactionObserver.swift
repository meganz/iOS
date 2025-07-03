import StoreKit

extension MEGAPurchase: SKPaymentTransactionObserver {
    public func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        let receipt = appStoreReceipt()

        var shouldSubmitReceiptOnRestore = true // If restore purchase, send receipt only once

        for transaction in transactions {
            logUpdatedTransaction(transaction, on: queue)
            switch transaction.transactionState {
            case .purchased:
                onPurchasedUpdatedTransaction(transaction, receipt: receipt)
            case .restored:
                onRestoredTransaction(transaction, shouldSubmitReceipt: &shouldSubmitReceiptOnRestore, receipt: receipt)
            case .failed:
                onFailedTransaction(transaction)
            default:
                break
            }
        }
    }

    private func onPurchasedUpdatedTransaction(_ transaction: SKPaymentTransaction, receipt: String?) {
        submitPurchase(receipt, transaction: transaction)
        purchaseDelegateOnSuccessPurchase()

        SVProgressHUD.dismiss()

        if isPurchasingPromotedPlan {
            setIsPurchasingPromotedPlan(false)
            handlePromotedPlanPurchaseResult(isSuccess: true)
        }
    }

    private func onRestoredTransaction(
        _ transaction: SKPaymentTransaction,
        shouldSubmitReceipt: inout Bool,
        receipt: String?
    ) {
        if shouldSubmitReceipt {
            submitPurchase(receipt, transaction: transaction)
            restoreDelegateOnSuccessRestore()
            shouldSubmitReceipt = false
        }

        SVProgressHUD.dismiss()
    }

    private func onFailedTransaction(_ transaction: SKPaymentTransaction) {
        guard let error = transaction.error else {
            MEGALogError("[StoreKit] Transaction failed with nil error: \(transaction.logInformation)")
            return
        }

        purchaseDelegate(onFailedPurchase: (error as NSError).code, message: error.localizedDescription)

        SVProgressHUD.dismiss()

        if isPurchasingPromotedPlan {
            setIsPurchasingPromotedPlan(false)
            if (error as? SKError)?.code != .paymentCancelled {
                handlePromotedPlanPurchaseResult(isSuccess: false)
            }
        }

        SKPaymentQueue.default().finishTransaction(transaction)
    }

    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        MEGALogDebug("[StoreKit] Restoring transactions finished with \(queue.transactions.count) transactions")

        if queue.transactions.isEmpty {
            restoreDelegateOnIncompleteRestore()
        }

        dismissProgressHUD()
    }

    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: any Error) {
        MEGALogDebug("[StoreKit] Restoring transactions failed with errorCode: \((error as NSError).code), message: \(error.localizedDescription)")
        restoreDelegate(onFailedRestore: (error as NSError).code, message: error.localizedDescription)
        dismissProgressHUD()
    }

    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        MEGALogDebug("[StoreKit] Initiated App Store promoted plan purchase for product: \(product.productIdentifier)")

        let shouldAddStorePayment = shouldAddStorePayment(for: product)
        setIsPurchasingPromotedPlan(shouldAddStorePayment)
        return shouldAddStorePayment
    }

    private func dismissProgressHUD() {
        guard SVProgressHUD.isVisible() else { return }

        SVProgressHUD.dismiss()
    }

    private func logUpdatedTransaction(
        _ transaction: SKPaymentTransaction,
        on paymentQueue: SKPaymentQueue
    ) {
        switch transaction.transactionState {
        case .purchasing:
            MEGALogDebug("[StoreKit] Transaction purchasing \(transaction.logInformation)")
        case .purchased:
            MEGALogDebug("[StoreKit] Transaction purchased \(transaction.logInformation)")
        case .restored:
            MEGALogDebug("[StoreKit] Transaction restored \(transaction.logInformation)")
        case .failed:
            MEGALogError("[StoreKit] Transaction failed \(transaction.logInformation)")
        case .deferred:
            MEGALogDebug("[StoreKit] Transaction deferred \(transaction.logInformation)")
        default:
            break
        }
    }
}

// MARK: - Log Helpers

extension SKPaymentTransaction {
    var logInformation: String {
        var information = ""
        information.logAppendNewLine(payment.productIdentifier, title: "Product Identifier")
        information.logAppendNewLine(payment.applicationUsername, title: "Application Username")
        information.logAppendNewLine(transactionIdentifier, title: "Transaction Identifier")
        information.logAppendNewLine(
            transactionDate?.formatted(date: .abbreviated, time: .shortened),
            title: "Transaction Date"
        )
        information.logAppendNewLine(original?.transactionIdentifier, title: "Original Transaction Identifier")
        information.logAppendNewLine(
            original?.transactionDate?.formatted(date: .abbreviated, time: .shortened),
            title: "Original Transaction Date"
        )
        information.logAppendNewLine(error?.localizedDescription, title: "Error")
        return information
    }
}

private extension String {
    mutating func logAppendNewLine(_ value: String?, title: String) {
        if let value {
            self += "\n\t- \(title): \(value)"
        }
    }
}
