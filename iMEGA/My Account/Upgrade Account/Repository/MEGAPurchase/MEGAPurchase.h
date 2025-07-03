#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@protocol MEGAPurchaseDelegate;
@protocol MEGARestoreDelegate;
@protocol MEGAPurchasePricingDelegate;

@interface MEGAPurchase : NSObject <MEGARequestDelegate>

@property (nonatomic, strong) NSMutableArray<id<MEGAPurchaseDelegate>> *purchaseDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGARestoreDelegate>> *restoreDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGAPurchasePricingDelegate>> *pricingsDelegateMutableArray;
@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic, strong) MEGACurrency *currency;
@property (nonatomic, readonly, getter=isPurchasingPromotedPlan) BOOL purchasingPromotedPlan;
@property (nonatomic, readonly, getter=isSubmittingReceipt) BOOL submittingReceipt;

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
- (void)setIsSubmittingReceipt:(BOOL)isSubmittingReceipt;

- (void)restoreDelegateOnSuccessRestore;
- (void)restoreDelegateOnIncompleteRestore;
- (void)restoreDelegateOnFailedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

- (void)purchaseDelegateOnSuccessPurchase;
- (void)purchaseDelegateOnFailedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;
- (void)purchaseDelegateOnSuccessSubmitReceipt;
- (void)purchaseDelegateOnFailedSubmitReceipt:(MEGAErrorType)errorType;

- (void)pricingDelegateOnPricingReady;

@end

@interface MEGAPurchase(Collection)
@property (nonatomic, strong) NSArray *products;
@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase;

@optional
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;
- (void)failedSubmitReceipt:(NSInteger)errorCode;
- (void)successSubmitReceipt;

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
