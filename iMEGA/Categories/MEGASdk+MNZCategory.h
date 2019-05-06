
NS_ASSUME_NONNULL_BEGIN

@interface MEGASdk (MNZCategory)

#pragma mark - properties

@property (nonatomic, setter=mnz_setAccountDetails:) MEGAAccountDetails *mnz_accountDetails;
@property (nonatomic, readonly) BOOL mnz_isProAccount;

#pragma mark - methods

- (void)handleAccountBlockedEvent:(MEGAEvent *)event;


@end

NS_ASSUME_NONNULL_END
