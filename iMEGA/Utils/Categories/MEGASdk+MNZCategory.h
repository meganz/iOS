
NS_ASSUME_NONNULL_BEGIN

@interface MEGASdk (MNZCategory)

#pragma mark - properties

@property (nonatomic, setter=mnz_setAccountDetails:, nullable) MEGAAccountDetails *mnz_accountDetails;
@property (nonatomic, readonly) BOOL mnz_isProAccount;
@property (nonatomic, readonly) NSMutableArray *completedTransfers;

@property (nonatomic, assign, setter=mnz_setShouldRequestAccountDetails:) BOOL mnz_shouldRequestAccountDetails;

@end

NS_ASSUME_NONNULL_END
