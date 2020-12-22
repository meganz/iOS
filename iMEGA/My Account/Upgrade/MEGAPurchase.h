
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MEGASdkManager.h"

@protocol MEGAPurchaseDelegate;
@protocol MEGARestoreDelegate;
@protocol MEGAPurchasePricingDelegate;

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

@property (nonatomic, weak) id<MEGAPurchaseDelegate>delegate;
@property (nonatomic, weak) id<MEGARestoreDelegate>restoreDelegate;
@property (nonatomic, weak) id<MEGAPurchasePricingDelegate>pricingsDelegate;
@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic, strong) NSMutableArray *products;

+ (MEGAPurchase *)sharedInstance;

- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchase;
- (NSUInteger)pricingProductIndexForProduct:(SKProduct *)product;

@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase;
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGARestoreDelegate <NSObject>

- (void)successfulRestore:(MEGAPurchase *)megaPurchase;
- (void)incompleteRestore;
- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

@end

@protocol MEGAPurchasePricingDelegate <NSObject>

- (void)pricingsReady;

@end
