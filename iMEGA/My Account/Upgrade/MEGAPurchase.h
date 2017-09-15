
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MEGASdkManager.h"

@protocol MEGAPurchaseDelegate;
@protocol MEGAPurchasePricingDelegate;

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

@property (assign) id<MEGAPurchaseDelegate>delegate;
@property (assign) id<MEGAPurchasePricingDelegate>pricingsDelegate;
@property (nonatomic, strong) SKProduct *validProduct;
@property (nonatomic, strong) MEGAPricing *pricing;

+ (MEGAPurchase *)sharedInstance;

- (void)requestProduct:(NSString *)productId;
- (void)purchaseProduct:(SKProduct *)requestedProduct;
- (void)restorePurchase;

@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)requestedProduct;
- (void)successfulPurchase:(MEGAPurchase *)megaPurchase restored:(BOOL)isRestore;
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;
- (void)incompleteRestore;
- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGAPurchasePricingDelegate <NSObject>

- (void)pricingsReady;

@end
