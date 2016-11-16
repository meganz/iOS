
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

- (void)requestProduct:(NSString *)productId {
    if (productId != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
            prodRequest.delegate = self;
            [prodRequest start];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"appPurchaseDisabled", nil)
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:AMLocalizedString(@"productNotFound", nil), productId]
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)purchaseProduct:(SKProduct *)requestedProduct {
    if (requestedProduct != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            SKMutablePayment *paymentRequest = [SKMutablePayment paymentWithProduct:requestedProduct];
            NSString *base64UserHandle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
            paymentRequest.applicationUsername = base64UserHandle;
            [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"appPurchaseDisabled", nil)
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:AMLocalizedString(@"productNotFound", nil), requestedProduct.productIdentifier]
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
    _validProduct = nil;
    NSUInteger count = [response.products count];
    if (count > 0) {
        _validProduct = [response.products objectAtIndex:0];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [_delegate requestedProduct];
}


#pragma mark - SKPaymentTransactionObserver Methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    MEGALogInfo(@"receipt URL: %@", receiptURL);
    
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) {
        MEGALogInfo(@"No receipt data");
    }
    
    BOOL shouldSubmitReceiptOnRestore = YES; // If restore purchase, send only one time the receipt.
    
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                break;
                
            case SKPaymentTransactionStatePurchased:
                MEGALogInfo(@"Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[receiptData base64EncodedStringWithOptions:0] delegate:self];
                
                [_delegate successfulPurchase:self restored:NO];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
                
            case SKPaymentTransactionStateRestored:
                MEGALogInfo(@"Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
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
    if ([request type] == MEGARequestTypeSubmitPurchaseReceipt) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];        
    }
    if (error.type) {
        if ([request type] == MEGARequestTypeSubmitPurchaseReceipt) {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"wrongPurchase", nil), [error name], (long)[error type]]];
        }
        return;
    }
    
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
    }
}

@end

