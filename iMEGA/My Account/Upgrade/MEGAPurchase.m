
#import "MEGAPurchase.h"

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
            // Yes, In-App Purchase is enabled on this device.
            // Initiate a product request of the Product ID.
            SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
            prodRequest.delegate = self;
            [prodRequest start];
            
        } else {
            // Notify user that In-App Purchase is Disabled.
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
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)purchaseProduct:(SKProduct *)requestedProduct {
    if (requestedProduct != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            // Yes, In-App Purchase is enabled on this device.
            // Proceed to purchase In-App Purchase item.
            // Assign a Product ID to a new payment request.
            SKPayment *paymentRequest = [SKPayment paymentWithProduct:requestedProduct];
            
            // Request a purchase of the product.
            [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
            
        } else {
            // Notify user that In-App Purchase is Disabled.
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
        // Yes, In-App Purchase is enabled on this device.
        // Proceed to restore purchases.
        // Request to restore previous purchases.
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
    } else {
        // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
        UIAlertView *settingsAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"allowPurchase_title", nil) message:AMLocalizedString(@"allowPurchase_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [settingsAlert show];
    }
}

#pragma mark - SKProductsRequestDelegate Methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    // Parse the received product info.
    _validProduct = nil;
    NSUInteger count = [response.products count];
    if (count > 0) {
        _validProduct = [response.products objectAtIndex:0];
    }
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [_delegate requestedProduct];
}


#pragma mark - SKPaymentTransactionObserver Methods

// The transaction status of the SKPaymentQueue is sent here.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
//    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
//    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchasing:
                // Item is still in the process of being purchased
                break;
                
            case SKPaymentTransactionStatePurchased:
                // Item was successfully purchased!
                
                [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[transaction.transactionReceipt base64EncodedDataWithOptions:0]];
                
                [_delegate successfulPurchase:self restored:NO];
                
                // After customer has successfully received purchased content,
                // remove the finished transaction from the payment queue.
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                // Verified that user has already paid for this item.
                // Ideal for restoring item across all devices of this customer.
                
                [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[transaction.transactionReceipt base64EncodedDataWithOptions:0]];
                
                // Return transaction data. App should provide user with purchased product.
                [_delegate successfulPurchase:self restored:YES];
                
                // After customer has restored purchased content on this device,
                // remove the finished transaction from the payment queue.
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                // Purchase was either cancelled by user or an error occurred.
                
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    
                    // A transaction error occurred, so notify user.
                    [_delegate failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                }
                
                // Finished transactions should be removed from the payment queue.
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
    // Release the transaction observer since transaction is finished/removed.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
//    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
//    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if ([queue.transactions count] == 0) {
        // Queue does not include any transactions, so either user has not yet made a purchase
        // or the user's prior purchase is unavailable, so notify app (and user) accordingly.
        
        [_delegate incompleteRestore];
        
    } else {
        // Queue does contain one or more transactions, so return transaction data.
        // App should provide user with purchased product.
        
        for(SKPaymentTransaction *transaction in queue.transactions) {
            [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[transaction.transactionReceipt base64EncodedDataWithOptions:0]];
            [_delegate successfulPurchase:self restored:YES];
        }
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    // Restore was cancelled or an error occurred, so notify user.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [_delegate failedRestore:error.code message:error.localizedDescription];
}



#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
    }
}

@end

