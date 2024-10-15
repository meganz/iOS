#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@protocol MEGAPurchaseDelegate;
@protocol MEGARestoreDelegate;
@protocol MEGAPurchasePricingDelegate;

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

@property (nonatomic, strong) NSMutableArray<id<MEGAPurchaseDelegate>> *purchaseDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGARestoreDelegate>> *restoreDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGAPurchasePricingDelegate>> *pricingsDelegateMutableArray;
@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic, readonly, getter=isPurchasingPromotedPlan) BOOL purchasingPromotedPlan;

+ (MEGAPurchase *)sharedInstance;
- (instancetype)initWithProducts:(NSArray<SKProduct *>*)products;

- (void)requestPricing;
- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchase;
- (NSUInteger)pricingProductIndexForProduct:(SKProduct *)product;
- (void)removeAllProducts;
- (SKProduct *)pendingPromotedProductForPayment;
- (void)savePendingPromotedProduct:(SKProduct *)product;
- (void)setIsPurchasingPromotedPlan:(BOOL)isPurchasing;

@end

@interface MEGAPurchase(Collection)
@property (nonatomic, readonly) NSArray *products;
@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase;

@optional
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGARestoreDelegate <NSObject>

- (void)successfulRestore:(MEGAPurchase *)megaPurchase;

@optional
- (void)incompleteRestore;
- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGAPurchasePricingDelegate <NSObject>

- (void)pricingsReady;

@end
#pragma GCC diagnostic push
