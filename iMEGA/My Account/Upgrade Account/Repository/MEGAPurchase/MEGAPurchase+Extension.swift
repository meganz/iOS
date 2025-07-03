import MEGAAppSDKRepo
import MEGAL10n
import MEGASdk
import StoreKit

extension MEGAPurchase {
    var sdk: MEGASdk { .sharedSdk }

    @objc func purchaseProduct(with product: SKProduct?) {
        guard let product else {
            MEGALogWarning("[StoreKit] Trying to purchase a nil product")
            let alertController = UIAlertController(
                title: Strings.Localizable.productNotFound(""), // If product is nil, there's no way to get the identifier
                message: nil,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel))
            UIApplication.mnz_presentingViewController().present(alertController, animated: true)
            return
        }

        guard SKPaymentQueue.canMakePayments() else {
            MEGALogWarning("[StoreKit] Trying to purchase but In-App Purchase is disabled")
            let alertController = UIAlertController.inAppPurchaseAlertWithAppStoreSettingsButton(
                Strings.Localizable.appPurchaseDisabled,
                alertMessage: nil
            )
            UIApplication.mnz_presentingViewController().present(alertController, animated: true)
            return
        }

        SVProgressHUD.show()
        addPaymentRequest(for: product)
    }

    private func addPaymentRequest(for product: SKProduct) {
        MEGALogDebug("[StoreKit] Purchasing product: \(product.productIdentifier)")
        let paymentRequest = SKMutablePayment(product: product)
        if let userHandle = base64userHandle() {
            paymentRequest.applicationUsername = userHandle
        } else {
            MEGALogWarning("[StoreKit] Unable to set applicationUsername for payment request, user handle is nil")
        }
        SKPaymentQueue.default().add(paymentRequest)
    }

    private func base64userHandle() -> String? {
        guard let currentUserHandle = MEGASdk.currentUserHandle()?.uint64Value else { return nil }

        return MEGASdk.base64Handle(forUserHandle: currentUserHandle)
    }

    @objc func startProductRequest(for productIdentifiers: Set<String>) {
        let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self
        productRequest.start()
    }

    @objc func appStoreProductIdentifiers() -> [String] {
        guard let productsCount = pricing?.products else {
            MEGALogWarning("[StoreKit] Requesting products aborted: Pricing is nil")
            return []
        }

        MEGALogDebug("[StoreKit] Request \(productsCount) products:")

        var productIdentifiers = [String]()
        for index in 0 ..< productsCount {
            let accountType = pricing.proLevel(atProductIndex: index).toAccountTypeEntity().toAccountTypeDisplayName()

            guard let productId = pricing.iOSID(atProductIndex: index) else {
                MEGALogWarning("[StoreKit] Product ID is nil at index \(index) for account type: \(accountType)")
                continue
            }

            guard !productId.isEmpty else {
                MEGALogWarning("[StoreKit] Product ID is empty at index: \(index) for account type: \(accountType)")
                continue
            }

            MEGALogDebug("[StoreKit] Product \(productId) for account type: \(accountType)")
            productIdentifiers.append(productId)
        }

        return productIdentifiers
    }

    @objc func appStoreReceipt() -> String? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            MEGALogWarning("[StoreKit] No receipt URL found")
            return nil
        }
        MEGALogDebug("[StoreKit] Receipt URL: \(receiptURL)")

        guard let receiptData = try? Data(contentsOf: receiptURL) else {
            MEGALogWarning("[StoreKit] Unable to read receipt data from URL: \(receiptURL)")
            return nil
        }

        let receipt = receiptData.base64EncodedString()
        MEGALogDebug("[StoreKit] Vpay receipt: \(receipt)")

        return receipt.isEmpty ? nil : receipt
    }

    @objc func submitPurchase(_ receipt: String?, transaction: SKPaymentTransaction) {
        guard let receipt else { return }

        sdk.submitPurchase(
            .itunes,
            receipt: receipt,
            delegate: MEGAPurchaseRequestDelegate(
                onRequestStartHandler: { [weak self] _ in
                    self?.setIsSubmittingReceipt(true)
                },
                completion: { [weak self, transaction] result in
                    switch result {
                    case .success:
                        self?.submitPurchaseSuccessful(for: transaction)
                    case .failure(let error):
                        // `apiEExist` is accepted because if a user is downgrading its subscription,
                        // this error will be returned by the API, because the receipt does not contain any new information.
                        if case .apiEExist = error.type {
                            self?.submitPurchaseSuccessful(for: transaction)
                        } else {
                            self?.submitPurchaseFailed(for: transaction, error: error)
                        }

                    }
                    self?.setIsSubmittingReceipt(false)
                }
            )
        )

        MEGALogDebug("[StoreKit] Submitted purchase receipt \(transaction.logInformation)")
    }

    private func submitPurchaseSuccessful(for transaction: SKPaymentTransaction) {
        purchaseDelegateOnSuccessSubmitReceipt()
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func submitPurchaseFailed(for transaction: SKPaymentTransaction, error: MEGAError) {
        purchaseDelegate(onFailedSubmitReceipt: error.type)
        SVProgressHUD.showError(withStatus: Strings.Localizable.wrongPurchase(error.name, error.type.rawValue))
    }

    @objc func restoreCompletedTransactions() {
        guard SKPaymentQueue.canMakePayments() else {
            MEGALogWarning("[StoreKit] In-App purchases is disabled")
            let alertController = UIAlertController.inAppPurchaseAlertWithAppStoreSettingsButton(
                Strings.Localizable.allowPurchaseTitle,
                alertMessage: Strings.Localizable.allowPurchaseMessage
            )
            UIApplication.mnz_presentingViewController().present(alertController, animated: true)
            return
        }

        SVProgressHUD.show()

        MEGALogDebug("[StoreKit] Restoring completed transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

fileprivate final class MEGAPurchaseRequestDelegate: NSObject, MEGARequestDelegate {
    private let onRequestStartHandler: ((MEGARequest) -> Void)?
    private let completion: ((Result<MEGARequest, MEGAError>) -> Void)?

    init(
        onRequestStartHandler: ((MEGARequest) -> Void)? = nil,
        completion: ((Result<MEGARequest, MEGAError>) -> Void)?
    ) {
        self.onRequestStartHandler = onRequestStartHandler
        self.completion = completion
        super.init()
    }

    func onRequestStart(_ api: MEGASdk, request: MEGARequest) {
        onRequestStartHandler?(request)
    }

    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        switch error.type {
        case .apiOk:
            completion?(.success(request))
        default:
            completion?(.failure(error))
        }
    }
}
