#import "MEGAPurchase.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface MEGAPurchase ()
@property (nonatomic, strong) NSArray *iOSProductIdentifiers;
@property (nonatomic, strong) NSMutableArray *products;
@property (nonatomic, strong) SKProduct *pendingStoreProduct;
@property (nonatomic, getter=isPurchasingPromotedPlan) BOOL purchasingPromotedPlan;
@property (nonatomic, getter=isSubmittingReceipt) BOOL submittingReceipt;
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
        self.products = [[NSMutableArray alloc] initWithCapacity:productIdentifieres.count];
        self.iOSProductIdentifiers = [productIdentifieres copy];
        SKProductsRequest *prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.iOSProductIdentifiers]];
        prodRequest.delegate = self;
        [prodRequest start];
        
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
    }
}

- (void)removeAllProducts {
    [self.products removeAllObjects];
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
        [SVProgressHUD show];
        
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        MEGALogWarning(@"[StoreKit] In-App purchases is disabled");
        
        UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:LocalizedString(@"allowPurchase_title", @"Alert title to remenber the user that needs to enable purchases") alertMessage:LocalizedString(@"allowPurchase_message", @"Alert message to remenber the user that needs to enable purchases before continue")];
        [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
    }
}

- (NSUInteger)pricingProductIndexForProduct:(SKProduct *)product {
    return [self.iOSProductIdentifiers indexOfObject:product.productIdentifier];
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
                if (receipt) {
                    [MEGASdk.shared submitPurchase:MEGAPaymentMethodItunes receipt:receipt delegate:self];
                }
                
                MEGALogDebug(@"[StoreKit] Transaction purchased");
                
                for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
                    [delegate successfulPurchase:self];
                }
                
                [SVProgressHUD dismiss];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                if (self.isPurchasingPromotedPlan) {
                    [self setIsPurchasingPromotedPlan:NO];
                    [self handlePromotedPlanPurchaseResultWithIsSuccess:YES];
                }
                
                break;
            }
                
            case SKPaymentTransactionStateRestored:
                MEGALogDebug(@"[StoreKit] Date: %@\nIdentifier: %@\n\t-Original Date: %@\n\t-Original Identifier: %@", transaction.transactionDate, transaction.transactionIdentifier, transaction.originalTransaction.transactionDate, transaction.originalTransaction.transactionIdentifier);
                if (shouldSubmitReceiptOnRestore) {
                    if (receipt) {
                        [MEGASdk.shared submitPurchase:MEGAPaymentMethodItunes receipt:receipt delegate:self];
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
                
                for (id<MEGAPurchaseDelegate> purchaseDelegate in self.purchaseDelegateMutableArray) {
                    if ([purchaseDelegate respondsToSelector:@selector(failedPurchase:message:)]) {
                        [purchaseDelegate failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                    }
                }
                
                [SVProgressHUD dismiss];
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
    
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    MEGALogDebug(@"[StoreKit] Restore failed with error %@", error);
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
        if ([restoreDelegate respondsToSelector:@selector(failedRestore:message:)]) {
            [restoreDelegate failedRestore:error.code message:error.localizedDescription];
        }
    }
    if ([SVProgressHUD isVisible]) {
        [SVProgressHUD dismiss];
    }
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    MEGALogDebug(@"[StoreKit] Initiated App store promoted plan purchase");
    
    BOOL shouldAddStorePayment = [self shouldAddStorePaymentFor:product];
    [self setIsPurchasingPromotedPlan:shouldAddStorePayment];
    
    return shouldAddStorePayment;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        [self setIsSubmittingReceipt:true];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
            //MEGAErrorTypeApiEExist is skipped because if a user is downgrading its subscription, this error will be returned by the API, because the receipt does not contain any new information.
            if (error.type != MEGAErrorTypeApiEExist) {
                for (id<MEGAPurchaseDelegate> purchaseDelegate in self.purchaseDelegateMutableArray) {
                    if ([purchaseDelegate respondsToSelector:@selector(failedSubmitReceipt:)]) {
                        [purchaseDelegate failedSubmitReceipt:error.type];
                    }
                }
                
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:LocalizedString(@"wrongPurchase", @"Error message shown when the purchase has failed"), error.name, (long)error.type]];
            }
            [self setIsSubmittingReceipt:false];
        }
        return;
    }
    
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
        [self requestProducts];
    } else if (request.type == MEGARequestTypeSubmitPurchaseReceipt) {
        [self setIsSubmittingReceipt:false];
        for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
            if ([delegate respondsToSelector:@selector(successSubmitReceipt)]) {
                [delegate successSubmitReceipt];
            }
        }
    }
}

@end
