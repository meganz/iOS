
#import "MEGAPurchase.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"
@import MEGAData;

@interface MEGAPurchase ()
@property (nonatomic, strong) NSArray *iOSProductIdentifiers;
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

- (void)requestPricing {
    [[MEGASdkManager sharedMEGASdk] getPricingWithDelegate:self];
}

- (void)requestProducts {
    MEGALogDebug(@"[StoreKit] Request %ld products:", (long)self.pricing.products);
    if ([SKPaymentQueue canMakePayments]) {
        NSMutableArray *productIdentifieres = [NSMutableArray.alloc initWithCapacity:self.pricing.products];
        for (NSInteger i = 0; i < self.pricing.products; i++) {
            NSString *productId = [self.pricing iOSIDAtProductIndex:i];
            MEGALogDebug(@"[StoreKit] Product \"%@\"", productId);
            if (productId.length) {
                [productIdentifieres addObject:productId];
            } else {
                MEGALogWarning(@"Product identifier \"%@\" (account type \"%@\") does not exist in the App Store, not need to request its information", productId, [MEGAAccountDetails stringForAccountType:[self.pricing proLevelAtProductIndex:i]]);
            }
        }
        _products = [[NSMutableArray alloc] initWithCapacity:productIdentifieres.count];
        self.iOSProductIdentifiers = [productIdentifieres copy];
        SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.iOSProductIdentifiers]];
        prodRequest.delegate = self;
        [prodRequest start];
        
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
    }
}

- (void)purchaseProduct:(SKProduct *)product {
    MEGALogDebug(@"[StoreKit] Purchase product \"%@\"", product.productIdentifier);
    if (product != nil) {
        if ([SKPaymentQueue canMakePayments]) {
            [SVProgressHUD show];
            
            SKMutablePayment *paymentRequest = [SKMutablePayment paymentWithProduct:product];
            NSString *base64UserHandle = [MEGASdk base64HandleForUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
            paymentRequest.applicationUsername = base64UserHandle;
            [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
        } else {
            MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
            
            UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:NSLocalizedString(@"appPurchaseDisabled", @"Error message shown the In App Purchase is disabled in the device Settings") alertMessage:nil];
            [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
        }
    } else {
        MEGALogWarning(@"[StoreKit] Product \"%@\" not found", product.productIdentifier);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"productNotFound", nil), product.productIdentifier] message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)restorePurchase {
    if ([SKPaymentQueue canMakePayments]) {
        [SVProgressHUD show];
        
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
        
        UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:NSLocalizedString(@"allowPurchase_title", @"Alert title to remenber the user that needs to enable purchases") alertMessage:NSLocalizedString(@"allowPurchase_message", @"Alert message to remenber the user that needs to enable purchases before continue")];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (NSUInteger)pricingProductIndexForProduct:(SKProduct *)product {
    return [self.iOSProductIdentifiers indexOfObject:product.productIdentifier];
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<MEGAPurchasePricingDelegate> pricingsDelegate in self.pricingsDelegateMutableArray) {
            [pricingsDelegate pricingsReady];
        }
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    MEGALogError(@"[StoreKit] Request did fail with error %@", error);
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
    
    BOOL shouldSubmitReceiptOnRestore = YES; // If restore purchase, send only one time the receipt.
    
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                MEGALogDebug(@"[StoreKit] Transaction purchasing");
                break;
                
            case SKPaymentTransactionStatePurchased: {
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                
                NSTimeInterval lastPublicTimestampAccessed = [NSUserDefaults.standardUserDefaults doubleForKey:MEGALastPublicTimestampAccessed];
                uint64_t lastPublicHandleAccessed = [[NSUserDefaults.standardUserDefaults objectForKey:MEGALastPublicHandleAccessed] unsignedLongLongValue];
                NSInteger lastPublicTypeAccessed = [NSUserDefaults.standardUserDefaults integerForKey:MEGALastPublicTypeAccessed];
                if (lastPublicTimestampAccessed && lastPublicHandleAccessed && lastPublicTypeAccessed && receipt) {
                    [MEGASdkManager.sharedMEGASdk submitPurchase:MEGAPaymentMethodItunes receipt:receipt lastPublicHandle:lastPublicHandleAccessed lastPublicHandleType:lastPublicTypeAccessed lastAccessTimestamp:(uint64_t)lastPublicTimestampAccessed delegate:self];
                } else {
                    if (receipt) {
                        [MEGASdkManager.sharedMEGASdk submitPurchase:MEGAPaymentMethodItunes receipt:receipt delegate:self];
                    }
                }
                
                MEGALogDebug(@"[StoreKit] Transaction purchased");
                
                for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
                    [delegate successfulPurchase:self];
                }
                
                [SVProgressHUD dismiss];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

                break;
            }
                
            case SKPaymentTransactionStateRestored:
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                if (shouldSubmitReceiptOnRestore) {
                    if (receipt) {
                        [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:receipt delegate:self];
                    }
                    MEGALogDebug(@"[StoreKit] Transaction restored");
                    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
                        [restoreDelegate successfulRestore:self];
                    }
                    shouldSubmitReceiptOnRestore = NO;
                }
                
                [SVProgressHUD dismiss];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                break;
                
            case SKPaymentTransactionStateFailed:
                MEGALogError(@"[StoreKit] Transaction failed");
                MEGALogError(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@, failed error: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier, transaction.error);
                
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    for (id<MEGAPurchaseDelegate> purchaseDelegate in self.purchaseDelegateMutableArray) {
                        if ([purchaseDelegate respondsToSelector:@selector(failedPurchase:message:)]) {
                            [purchaseDelegate failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                        }
                    }
                }
                
                [SVProgressHUD dismiss];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateDeferred:
                MEGALogDebug(@"[StoreKit] Transaction deferred");
                break;
                
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if ([queue.transactions count] == 0) {
        for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
            if ([restoreDelegate respondsToSelector:@selector(incompleteRestore)]) {
                [restoreDelegate incompleteRestore];
            }
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
        if ([restoreDelegate respondsToSelector:@selector(failedRestore:message:)]) {
            [restoreDelegate failedRestore:error.code message:error.localizedDescription];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
            //MEGAErrorTypeApiEExist is skipped because if a user is downgrading its subscription, this error will be returned by the API, because the receipt does not contain any new information.
            if (error.type != MEGAErrorTypeApiEExist) {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"wrongPurchase", @"Error message shown when the purchase has failed"), error.name, (long)error.type]];
            }
        }
        return;
    }
    
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
        [self requestProducts];
    }
}

@end
