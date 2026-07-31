#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@protocol MEGAPurchaseDelegate;
@protocol MEGARestoreDelegate;
@protocol MEGAPurchasePricingDelegate;

/// Why the pricings could not be made ready. Every case is terminal for the request that produced it:
/// no `pricingsReady` will follow unless a brand new pricing request is started.
typedef NS_ENUM(NSInteger, MEGAPurchasePricingErrorCode) {
    /// The device cannot make payments, so the products were never requested from the App Store.
    MEGAPurchasePricingErrorCodePaymentsDisabled,
    /// The API pricing request failed, so there are no product identifiers to ask the App Store for.
    MEGAPurchasePricingErrorCodePricingRequestFailed,
    /// The App Store products request failed, so there are no `SKProduct`s to purchase.
    MEGAPurchasePricingErrorCodeProductsRequestFailed
};

@interface MEGAPurchase : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver, MEGARequestDelegate>

// These 3 mutable arrays are exposed so that Swift extensions can read and modify them
// DO NOT DIRECTLY MODIFY THESE ARRAYS, use the methods in MEGAPurchase+Delegates instead!
@property (nonatomic, strong) NSMutableArray<id<MEGAPurchaseDelegate>> *purchaseDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGARestoreDelegate>> *restoreDelegateMutableArray;
@property (nonatomic, strong) NSMutableArray<id<MEGAPurchasePricingDelegate>> *pricingsDelegateMutableArray;

@property (nonatomic, strong) MEGAPricing *pricing;
@property (nonatomic, strong) MEGACurrency *currency;
@property (nonatomic, readonly, getter=isPurchasingPromotedPlan) BOOL purchasingPromotedPlan;
@property (nonatomic, readonly, getter=isSubmittingReceipt) BOOL submittingReceipt;

+ (MEGAPurchase *)sharedInstance;
- (instancetype)initWithProducts:(NSArray<SKProduct *>*)products;

/// Starts a pricing request and broadcasts the outcome to the `MEGAPurchasePricingDelegate`s.
///
/// DO NOT CALL THIS DIRECTLY, use `PricingRequester.requestPricing` instead.
/// This method is fire-and-forget and keeps no track of whether a request is already running, so calling
/// it directly starts a second one. `PricingRequester` owns the state of the single shared request: it
/// only calls into here when there is nothing to join, makes concurrent callers wait on that one request
- (void)requestPricing;

/// Cancels the App Store products request started by `requestPricing`, if one is still running.
///
/// DO NOT CALL THIS DIRECTLY, use `PricingRequester.cancel` instead, which also releases the callers
/// waiting on that request.
/// Cancelling an `SKProductsRequest` produces no delegate callback, so neither `pricingsReady` nor
/// `pricingsFailed` follows: nothing here will release those waiters.
/// The SDK pricing leg cannot be cancelled, so a request still waiting on `getPricing` runs to completion
/// and may repopulate `products`. `PricingRequester` ignores that outcome.
- (void)cancelPricingRequest;
- (void)purchaseProduct:(SKProduct *)product;
- (void)restorePurchase;
- (NSUInteger)pricingProductIndexForProduct:(SKProduct *)product;
- (void)removeAllProducts;
- (SKProduct *)pendingPromotedProductForPayment;
- (void)savePendingPromotedProduct:(SKProduct *)product;
- (void)setIsPurchasingPromotedPlan:(BOOL)isPurchasing;
- (void)setIsSubmittingReceipt:(BOOL)isSubmittingReceipt;

@end

@interface MEGAPurchase(Collection)
@property (nonatomic, readonly) NSArray *products;
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

/// Sent when the pricings will not become ready, so waiters can stop waiting instead of hanging forever.
- (void)pricingsFailed;

@end
#pragma GCC diagnostic push
