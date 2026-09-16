#import "MEGAPurchase.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"

#import "LocalizationHelper.h"
@import MEGAAppSDKRepo;

@interface MEGAPurchase ()
/// The iOS product identifiers of the plans in the last pricing request, kept only to detect whether
/// that set has changed and a new `SKProductsRequest` is therefore needed. It must be updated alongside with self.pricing.
///
/// Do not index into it to reach `pricing`
/// To resolve a product against `pricing`, use `productIndex(for:)` in `MEGAPurchase+Pricing.swift`.
@property (nonatomic, strong) NSArray *iOSProductIdentifiers;
@property (atomic, strong) NSMutableArray *products;
@property (nonatomic, strong) SKProduct *pendingStoreProduct;
@property (nonatomic, getter=isPurchasingPromotedPlan) BOOL purchasingPromotedPlan;
@property (nonatomic, getter=isSubmittingReceipt) BOOL submittingReceipt;
@property (nonatomic, strong, nullable) NSArray<SKPaymentTransaction *> *submittingTransactions;
@property (nonatomic, strong, nullable) SKProductsRequest *productsRequest;

- (void)notifyPricingsFailedWithErrorCode:(MEGAPurchasePricingErrorCode)errorCode;
@end

@implementation MEGAPurchase

+ (MEGAPurchase *)sharedInstance {
    static dispatch_once_t onceToken;
    static MEGAPurchase * storeManagerSharedInstance;

    dispatch_once(&onceToken, ^{
        storeManagerSharedInstance = [[MEGAPurchase alloc] init];
    });
    return storeManagerSharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        self.purchaseDelegateMutableArray = NSMutableArray.new;
        self.restoreDelegateMutableArray = NSMutableArray.new;
        self.pricingsDelegateMutableArray = NSMutableArray.new;
    }
    return self;
}

- (instancetype)initWithProducts:(NSArray<SKProduct *> *)products {
    self = [self init];
    if (self != nil) {
        self.products = [products mutableCopy];
    }

    return self;
}

- (void)requestPricing {
    [MEGASdk.shared getPricingWithDelegate:self];
}

- (void)requestProducts {
    MEGALogDebug(@"[StoreKit] Request %ld products:", (long)self.pricing.products);
    if ([SKPaymentQueue canMakePayments]) {
        self.products = [[NSMutableArray alloc] initWithCapacity:self.iOSProductIdentifiers.count];
        if (self.productsRequest) {
            [self.productsRequest cancel];
            self.productsRequest = nil;
        }
        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.iOSProductIdentifiers]];
        self.productsRequest.delegate = self;
        [self.productsRequest start];
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
        [self notifyPricingsFailedWithErrorCode:MEGAPurchasePricingErrorCodePaymentsDisabled];
    }
}

- (void)notifyPricingsReady {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<MEGAPurchasePricingDelegate> pricingsDelegate in self.pricingDelegates) {
            [pricingsDelegate pricingsReady];
        }
    });
}

- (void)notifyPricingsFailedWithErrorCode:(MEGAPurchasePricingErrorCode)errorCode {
    MEGALogError(@"[StoreKit] Pricings will not become ready, error code %ld", (long)errorCode);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<MEGAPurchasePricingDelegate> pricingsDelegate in self.pricingDelegates) {
            [pricingsDelegate pricingsFailed];
        }
    });
}

- (void)cancelPricingRequest {
    if (self.productsRequest) {
        MEGALogDebug(@"[StoreKit] Cancelling the products request");
        [self.productsRequest cancel];
        self.productsRequest = nil;
    }
}

/// Empties the catalogue. The loaded products stop being valid, so `PricingRequester.cancel` has to be
/// called alongside this, otherwise the next pricing request reuses this emptied catalogue.
- (void)removeAllProducts {
    [self.products removeAllObjects];
}

- (void)purchaseProduct:(SKProduct *)product {
    MEGALogDebug(@"[StoreKit] Purchase product \"%@\"", product.productIdentifier);
    if (product != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            [self showBlockingHUD];
            [self submitPaymentForProduct:product];
        } else {
            MEGALogWarning(@"[StoreKit] In-App purchases is disabled");

            UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:LocalizedString(@"appPurchaseDisabled", @"Error message shown the In App Purchase is disabled in the device Settings") alertMessage:nil];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        }
    } else {
        MEGALogWarning(@"[StoreKit] Product \"%@\" not found", product.productIdentifier);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:LocalizedString(@"productNotFound", @""), product.productIdentifier] message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }

    [self savePendingPromotedProduct:nil];
}

- (void)restorePurchase {
    if ([SKPaymentQueue canMakePayments]) {
        [self showBlockingHUD];

        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");

        UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:LocalizedString(@"allowPurchase_title", @"Alert title to remenber the user that needs to enable purchases") alertMessage:LocalizedString(@"allowPurchase_message", @"Alert message to remenber the user that needs to enable purchases before continue")];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (SKProduct *)pendingPromotedProductForPayment {
    return self.pendingStoreProduct;
}

- (void)savePendingPromotedProduct:(SKProduct *)product {
    self.pendingStoreProduct = product;
}

- (void)setIsPurchasingPromotedPlan:(BOOL)isPurchasing {
    // If isPurchasing is true, the promoted plan is ongoing
    // If isPurchasing is false, the promoted plan purchase is not active or has finished
    self.purchasingPromotedPlan = isPurchasing;
}

- (void)setIsSubmittingReceipt:(BOOL)isSubmittingReceipt {
    self.submittingReceipt = isSubmittingReceipt;
}

#pragma mark - SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    MEGALogDebug(@"[StoreKit] Products request did receive response %lu products", (unsigned long)response.products.count);

    NSArray *sortedProducts = [response.products sortedArrayUsingComparator:^NSComparisonResult(SKProduct *a, SKProduct *b) {
        return [a.productIdentifier compare:b.productIdentifier];
    }];

    for (SKProduct *product in sortedProducts) {
        MEGALogDebug(@"[StoreKit] Product \"%@\" received", product.productIdentifier);
        [self.products addObject:product];
    }

    for (NSString *invalidProductIdentifiers in response.invalidProductIdentifiers) {
        MEGALogError(@"[StoreKit] Invalid product \"%@\"", invalidProductIdentifiers);
    }

    [self notifyPricingsReady];
    [self checkForExpiredOrCancellation];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    MEGALogError(@"[StoreKit] Request did fail with error %@", error);
    if (self.productsRequest == request) {
        [self notifyPricingsFailedWithErrorCode:MEGAPurchasePricingErrorCodeProductsRequestFailed];
    }
    [self checkForExpiredOrCancellation];
}

#pragma mark - SKPaymentTransactionObserver Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    MEGALogDebug(@"[StoreKit] Receipt URL: %@", receiptURL);

    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receipt;
    if (receiptData) {
        receipt = [receiptData base64EncodedStringWithOptions:0];
        MEGALogDebug(@"[StoreKit] Vpay receipt: %@", receipt);
    } else {
        MEGALogWarning(@"[StoreKit] No receipt data");
    }

    // We should only submit receipt once, because there's no point to submit the same receipt multiple times
    // Even if there is multiple transactions, they will be processed in the same way
    BOOL hasSubmittedReceipt = NO;

    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                MEGALogDebug(@"[StoreKit] Transaction purchasing");
                break;

            // Inside `transactions` there could be multiple transactions with `SKPaymentTransactionStatePurchased` state
            // For the first `SKPaymentTransactionStatePurchased` transaction in the array, we will call `submitPurchase` with the latest
            // AppStore receipt, if the receipt is still valid, sdk will callback and update user's pro status.
            // For the latter `SKPaymentTransactionStatePurchased` transactions (if any) in the for-loop, we check `hasSubmittedReceipt` to avoid redundant calls of `submitPurchase`
            case SKPaymentTransactionStatePurchased: {
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                [self submitReceiptIfNeededWithReceipt:receipt transactions:transactions hasSubmittedReceipt:&hasSubmittedReceipt];

                MEGALogDebug(@"[StoreKit] Transaction purchased");

                for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegates) {
                    [delegate successfulPurchase:self];
                }

                [self dismissBlockingHUD];

                if (self.isPurchasingPromotedPlan) {
                    [self setIsPurchasingPromotedPlan:NO];
                    [self handlePromotedPlanPurchaseResultWithIsSuccess:YES];
                }

                break;
            }

            // Here we apply similar logic as the case for `SKPaymentTransactionStatePurchased`,
            // Only call `submitPurchase` for the first found transaction with `SKPaymentTransactionStatePurchased`
            case SKPaymentTransactionStateRestored:
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                if (!hasSubmittedReceipt) {
                    [self submitReceiptIfNeededWithReceipt:receipt transactions:transactions hasSubmittedReceipt:&hasSubmittedReceipt];
                    MEGALogDebug(@"[StoreKit] Transaction restored");
                    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegates) {
                        [restoreDelegate successfulRestore:self];
                    }
                }

                [self dismissBlockingHUD];

                break;

            case SKPaymentTransactionStateFailed:
                MEGALogError(@"[StoreKit] Transaction failed");
                MEGALogError(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@, failed error: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier, transaction.error);
                if (transaction.error) {
                    [self recordPurchaseError:transaction.error promotionalOfferId:transaction.payment.paymentDiscount.identifier];
                }

                for (id<MEGAPurchaseDelegate> purchaseDelegate in self.purchaseDelegates) {
                    if ([purchaseDelegate respondsToSelector:@selector(failedPurchase:message:)]) {
                        [purchaseDelegate failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                    }
                }

                [self dismissBlockingHUD];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                if (self.isPurchasingPromotedPlan) {
                    [self setIsPurchasingPromotedPlan:NO];

                    if (transaction.error.code != SKErrorPaymentCancelled) {
                        [self handlePromotedPlanPurchaseResultWithIsSuccess:NO];
                    }
                }
                break;

            case SKPaymentTransactionStateDeferred:
                MEGALogDebug(@"[StoreKit] Transaction deferred");
                // Ask to Buy: no further callback arrives until the parent decides, possibly only
                // after a relaunch, so the blocking HUD must come down now or the app stays frozen.
                [self dismissBlockingHUD];
                break;

            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if ([queue.transactions count] == 0) {
        for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegates) {
            if ([restoreDelegate respondsToSelector:@selector(incompleteRestore)]) {
                [restoreDelegate incompleteRestore];
            }
        }
    }

    if ([SVProgressHUD isVisible]) {
        [self dismissBlockingHUD];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    MEGALogDebug(@"[StoreKit] Restore failed with error %@", error);
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegates) {
        if ([restoreDelegate respondsToSelector:@selector(failedRestore:message:)]) {
            [restoreDelegate failedRestore:error.code message:error.localizedDescription];
        }
    }
    if ([SVProgressHUD isVisible]) {
        [self dismissBlockingHUD];
    }
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    MEGALogDebug(@"[StoreKit] Initiated App store promoted plan purchase");

    BOOL shouldAddStorePayment = [self shouldAddStorePaymentFor:product];
    [self setIsPurchasingPromotedPlan:shouldAddStorePayment];

    return shouldAddStorePayment;
}

- (void)submitReceiptIfNeededWithReceipt:(NSString *)receipt transactions:(NSArray<SKPaymentTransaction *> *)transactions hasSubmittedReceipt:(BOOL *)hasSubmittedReceipt {
    if (receipt && !(*hasSubmittedReceipt) && !self.isSubmittingReceipt) {
        [MEGASdk.shared submitPurchase:MEGAPaymentMethodItunes receipt:receipt delegate:self];
        self.submittingTransactions = [transactions copy];
        *hasSubmittedReceipt = YES;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        MEGALogDebug(@"[StoreKit] Submitting receipt for purchase");
        [self setIsSubmittingReceipt:true];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (request.type == MEGARequestTypeGetPricing) {
            MEGALogError(@"[StoreKit] Get pricing failed with error: %@ - %ld", error.name, (long)error.type);
            [self notifyPricingsFailedWithErrorCode:MEGAPurchasePricingErrorCodePricingRequestFailed];
        } else if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
            //MEGAErrorTypeApiEExist is skipped because if a user is downgrading its subscription, this error will be returned by the API, because the receipt does not contain any new information.
            if (error.type == MEGAErrorTypeApiEExist) {
                MEGALogDebug(@"[StoreKit] Submitting receipt failed with error: %@ - %ld, but it is expected when downgrading subscription", error.name, (long)error.type);
                [self finishSubmittedTransactions];
            } else if (error.type == MEGAErrorTypeApiEExpired) {
                // According to API, MEGAErrorTypeApiEExpired will be returned `when all purchases in the receipt have expired`.
                // In this case the submitted receipt is no longer useful and we can skip the error.
                MEGALogDebug(@"[StoreKit] Submitting receipt failed with error: %@ - %ld, but it is expected when the receipt has expired", error.name, (long)error.type);
                [self finishSubmittedTransactions];
            } else {
                MEGALogError(@"[StoreKit] Submitting receipt failed with error: %@ - %ld", error.name, (long)error.type);
                for (id<MEGAPurchaseDelegate> purchaseDelegate in self.purchaseDelegates) {
                    if ([purchaseDelegate respondsToSelector:@selector(failedSubmitReceipt:)]) {
                        [purchaseDelegate failedSubmitReceipt:error.type];
                    }
                }

                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:LocalizedString(@"wrongPurchase", @"Error message shown when the purchase has failed"), error.name, (long)error.type]];
            }
            [self setIsSubmittingReceipt:false];
            self.submittingTransactions = nil;
        }
        return;
    }

    if (request.type == MEGARequestTypeGetPricing) {
        [self handleSucceededPricingRequest:request];
    } else if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        MEGALogDebug(@"[StoreKit] Receipt submitted successfully");
        [self setIsSubmittingReceipt:false];
        for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegates) {
            if ([delegate respondsToSelector:@selector(successSubmitReceipt)]) {
                [delegate successSubmitReceipt];
            }
        }
        [self finishSubmittedTransactions];
        self.submittingTransactions = nil;
    }
}

/// Pricing (MEGAPricing) contains plan details configured via our API, such as
/// price, currency, storage quota, and any available offers.
/// It includes plan details for MEGA Cloud, VPN, and PWM.
///
/// Products (SKProduct) contains subscription details configured in App Store Connect.
/// It includes all subscriptions available in the MEGA Cloud app, including those
/// used primarily for testing and those that are no longer supported by our API.
///
/// The valid, supported products for MEGA Cloud are the intersection of Pricing and Products.
/// This set is unlikely to change unless we add support for new MEGA Cloud subscriptions configured in App Store Connect.
/// What may change frequently is the offer associated with a given plan.
///
/// When there is an ongoing offer, a promotional dialog may be shown to users.
/// The API guarantees that once a user upgrades during a campaign, it will stop
/// exposing offers for that user in MEGAPricing.
/// Therefore, we should refresh MEGAPricing regularly to ensure that offers remain up to date.
///
/// As a result, Products do not need to be requested again once they have been loaded.
- (void)handleSucceededPricingRequest:(MEGARequest *)request {
    self.pricing = request.pricing;
    self.currency = request.currency;
    NSMutableArray *productIdentifieres = [NSMutableArray.alloc initWithCapacity:self.pricing.products];
    for (NSInteger i = 0; i < self.pricing.products; i++) {
        NSString *productId = [self.pricing iOSIDAtProductIndex:i];
        MEGALogDebug(@"[Pricing] Product \"%@\"", productId);
        if (productId.length) {
            [productIdentifieres addObject:productId];
        } else {
            MEGALogWarning(@"[Pricing] Product identifier \"%@\" (account type \"%@\") does not exist in the App Store, not need to request its information", productId, [MEGAAccountDetails stringForAccountType:[self.pricing proLevelAtProductIndex:i]]);
        }
    }
    
    BOOL isProductIdentifiersUnchanged = [self isIOSProductIdentifiersUnchanged:productIdentifieres];
    BOOL isProductsLoaded = self.products && self.products.count > 0;
    
    // Replaced on every path, right after the comparison that reads the previous value, so it always
    // describes the same pricing request as `self.pricing` above.
    self.iOSProductIdentifiers = [productIdentifieres copy];

    if (isProductsLoaded && isProductIdentifiersUnchanged) {
        // Products are already loaded, so notify that pricing is ready immediately.
        // Otherwise, PricingRequester.refreshPricing will be awaiting forever.
        [self notifyPricingsReady];
    } else if (!isProductsLoaded) {
        // Products are not loaded yet, proceeding with product request.
        // The product request delegate will call either notifyPricingsReady or notifyPricingsFailed upon completion.
        [self requestProducts];
    } else {
        // A different set of identifiers, proceeding with product request.
        // The product request delegate will call either notifyPricingsReady or notifyPricingsFailed upon completion.
        MEGALogWarning(@"[Pricing] Product identifiers have changed");
        [self requestProducts];
    }
}

/// Why a set comparison rather than an array comparison.
///
/// The order of `iOSProductIdentifiers` does not matter when fetching metadata for a given `SKProduct`.
///
/// `self.pricing` and `self.iOSProductIdentifiers` needed to be updated together because
/// their underlying order was kept in sync. Given an `SKProduct.productIdentifier`, its index in
/// `iOSProductIdentifiers` was expected to match the index of the corresponding product in `self.pricing`.
///
/// However, using `iOSProductIdentifiers` to look up a product index can be confusing and error-prone.
/// Instead, please use `productIndex(for product: SKProduct)` in `MEGAPurchase+Pricing.swift`,
/// which searches through `pricing.products`.

/// `iOSProductIdentifiers` is now used only to determine whether the product identifiers have changed
/// between pricing requests. This determines whether a subsequent product request needs to be made.
///
/// Comparing arrays is order-sensitive. As a result, the same set of product identifiers in a different
/// order would cause `isIOSProductIdentifiersUnchanged` to return `false`, resulting in an unnecessary product request.
- (BOOL)isIOSProductIdentifiersUnchanged:(NSArray *)productIdentifiers {
    return [[NSSet setWithArray:self.iOSProductIdentifiers] isEqualToSet:[NSSet setWithArray:productIdentifiers]];
}

- (void)finishSubmittedTransactions {
    for (SKPaymentTransaction *transaction in self.submittingTransactions) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

#pragma mark - Blocking HUD

/// Shows the progress HUD with a mask that swallows every touch, so the screen that started the
/// payment cannot be dismissed while it is resolving. Paired with `dismissBlockingHUD`, which puts
/// the app-wide default mask back.
- (void)showBlockingHUD {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
}

/// Dismisses the HUD and restores the default mask. Called on every path that ends a payment or a
/// restore, so the mask is never left blocking.
- (void)dismissBlockingHUD {
    [SVProgressHUD dismiss];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
}


@end
