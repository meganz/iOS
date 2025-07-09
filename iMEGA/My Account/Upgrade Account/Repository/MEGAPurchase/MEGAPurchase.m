#import "MEGAPurchase.h"

#import "SVProgressHUD.h"

#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAAppSDKRepo;

@interface MEGAPurchase ()
@property (nonatomic, strong) NSArray *iOSProductIdentifiers;
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
    if ([SKPaymentQueue canMakePayments]) {
        NSArray *productIdentifiers = [self appStoreProductIdentifiers];
        self.products = [NSMutableArray arrayWithCapacity:productIdentifiers.count];
        self.iOSProductIdentifiers = productIdentifiers;
        [self startProductRequestFor:[NSSet setWithArray:productIdentifiers]];
    } else {
        MEGALogWarning(@"[StoreKit] Requesting products aborted: In-App purchases is disabled");
    }
}

- (void)removeAllProducts {
    [self.products removeAllObjects];
}

- (void)purchaseProduct:(SKProduct *)product {
    [self purchaseProductWith:product];
    [self savePendingPromotedProduct:nil];
}

- (void)restorePurchase {
    [self restoreCompletedTransactions];
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

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (request.type == MEGARequestTypeGetPricing) {
        self.pricing = request.pricing;
        self.currency = request.currency;
        [self requestProducts];
    }
}

#pragma mark - MEGARestoreDelegate

- (void)restoreDelegateOnSuccessRestore {
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
        [restoreDelegate successfulRestore:self];
    }
}

- (void)restoreDelegateOnIncompleteRestore {
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
        if ([restoreDelegate respondsToSelector:@selector(incompleteRestore)]) {
            [restoreDelegate incompleteRestore];
        }
    }
}

- (void)restoreDelegateOnFailedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    for (id<MEGARestoreDelegate> restoreDelegate in self.restoreDelegateMutableArray) {
        if ([restoreDelegate respondsToSelector:@selector(failedRestore:message:)]) {
            [restoreDelegate failedRestore:errorCode message:errorMessage];
        }
    }
}

#pragma mark - MEGAPurchaseDelegate

- (void)purchaseDelegateOnSuccessPurchase {
    for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
        [delegate successfulPurchase:self];
    }
}

- (void)purchaseDelegateOnFailedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
        if ([delegate respondsToSelector:@selector(failedPurchase:message:)]) {
            [delegate failedPurchase:errorCode message:errorMessage];
        }
    }
}

- (void)purchaseDelegateOnSuccessSubmitReceipt {
    for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
        if ([delegate respondsToSelector:@selector(successSubmitReceipt)]) {
            [delegate successSubmitReceipt];
        }
    }
}

- (void)purchaseDelegateOnFailedSubmitReceipt:(MEGAErrorType)errorType {
    for (id<MEGAPurchaseDelegate> delegate in self.purchaseDelegateMutableArray) {
        if ([delegate respondsToSelector:@selector(failedSubmitReceipt:)]) {
            [delegate failedSubmitReceipt:errorType];
        }
    }
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingDelegateOnPricingReady {
    for (id<MEGAPurchasePricingDelegate> pricingsDelegate in self.pricingsDelegateMutableArray) {
        [pricingsDelegate pricingsReady];
    }
}

@end
