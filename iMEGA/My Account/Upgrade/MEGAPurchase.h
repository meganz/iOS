
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MEGASdkManager.h"

@protocol MEGAPurchaseDelegate;

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

@property (assign) id<MEGAPurchaseDelegate>delegate;
@property (nonatomic, strong) SKProduct *validProduct;
@property (nonatomic, strong) MEGAPricing *pricing;

+ (MEGAPurchase *)sharedInstance;

- (void)requestProduct:(NSString *)productId;
- (void)purchaseProduct:(SKProduct *)requestedProduct;
- (void)restorePurchase;

@end

@protocol MEGAPurchaseDelegate <NSObject>

- (void)requestedProduct;
- (void)successfulPurchase:(MEGAPurchase *)megaPurchase restored:(BOOL)isRestore identifier:(NSString *)productId receipt:(NSData *)receipt;
- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage;
- (void)incompleteRestore;
- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage;

@end
