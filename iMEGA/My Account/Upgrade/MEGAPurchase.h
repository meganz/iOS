
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MEGASdkManager.h"

@protocol MEGAPurchaseDelegate;
@protocol MEGAPurchasePricingDelegate;

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

@property (assign) id<MEGAPurchaseDelegate>delegate;
@property (assign) id<MEGAPurchasePricingDelegate>pricingsDelegate;
@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic, strong) NSMutableArray *products;

+ (MEGAPurchase *)sharedInstance;

- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchase;

@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase restored:(BOOL)isRestore;
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;
- (void)incompleteRestore;
- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGAPurchasePricingDelegate <NSObject>

- (void)pricingsReady;

@end
