
#import "MEGAPurchase.h"
#import "SVProgressHUD.h"

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
        [[MEGASdkManager sharedMEGASdk] getPricingWithDelegate:self];
    }
    return self;
}

- (void)requestProducts {
    MEGALogDebug(@"[StoreKit] Request %ld products:", (long)self.pricing.products);
    if ([SKPaymentQueue canMakePayments]) {
        NSMutableSet *productIdentifieres = [[NSMutableSet alloc] initWithCapacity:self.pricing.products];
        for (NSInteger i = 0; i < self.pricing.products; i++) {
            MEGALogDebug(@"[StoreKit] Product \"%@\"", [self.pricing iOSIDAtProductIndex:i]);
            [productIdentifieres addObject:[self.pricing iOSIDAtProductIndex:i]];
        }
        _products = [[NSMutableArray alloc] initWithCapacity:productIdentifieres.count];
        SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifieres];
        prodRequest.delegate = self;
        [prodRequest start];
        
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"appPurchaseDisabled", nil)
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)purchaseProduct:(SKProduct *)product {
    MEGALogDebug(@"[StoreKit] Purchase product \"%@\"", product.productIdentifier);
    if (product != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            SKMutablePayment *paymentRequest = [SKMutablePayment paymentWithProduct:product];
            NSString *base64UserHandle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
            paymentRequest.applicationUsername = base64UserHandle;
            [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
        } else {
            MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"appPurchaseDisabled", nil)
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    } else {
        MEGALogWarning(@"[StoreKit] Product \"%@\" not found", product.productIdentifier);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:AMLocalizedString(@"productNotFound", nil), product.productIdentifier]
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)restorePurchase {
    if ([SKPaymentQueue canMakePayments]) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
    } else {
        UIAlertView *settingsAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"allowPurchase_title", nil) message:AMLocalizedString(@"allowPurchase_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [settingsAlert show];
    }
}

#pragma mark - SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    MEGALogDebug(@"[StoreKit] Products request did receive response %lu products", (unsigned long)response.products.count);
    for (SKProduct *product in response.products) {
        [self.products addObject:product];
    }
    for (NSString *invalidProductIdentifiers in response.invalidProductIdentifiers) {
        MEGALogError(@"[StoreKit] Invalid product \"%@\"", invalidProductIdentifiers);
    }
    
    [self.pricingsDelegate pricingsReady];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    MEGALogError(@"[StoreKit] Request did fail with error %@", error);
}


#pragma mark - SKPaymentTransactionObserver Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    MEGALogDebug(@"[StoreKit] Receipt URL: %@", receiptURL);
    
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) {
        MEGALogWarning(@"[StoreKit] No receipt data");
    }
    
    BOOL shouldSubmitReceiptOnRestore = YES; // If restore purchase, send only one time the receipt.
    
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                break;
                
            case SKPaymentTransactionStatePurchased:
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[receiptData base64EncodedStringWithOptions:0] delegate:self];
                
                [_delegate successfulPurchase:self restored:NO];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
                
            case SKPaymentTransactionStateRestored:
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                if (shouldSubmitReceiptOnRestore) {
                    [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[receiptData base64EncodedStringWithOptions:0] delegate:self];
                    [_delegate successfulPurchase:self restored:YES];
                    shouldSubmitReceiptOnRestore = NO;
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
                
            case SKPaymentTransactionStateFailed:
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    [_delegate failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                }
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if ([queue.transactions count] == 0) {
        [_delegate incompleteRestore];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [_delegate failedRestore:error.code message:error.localizedDescription];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];        
    }
    if (error.type) {
        if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"wrongPurchase", nil), [error name], (long)[error type]]];
        }
        return;
    }
    
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
        [self requestProducts];
    }
}

@end

