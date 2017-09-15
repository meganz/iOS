
@interface MEGASdk (MNZCategory)

@property (nonatomic, setter=mnz_setAccountDetails:) MEGAAccountDetails *mnz_accountDetails;
@property (nonatomic, readonly) BOOL mnz_isProAccount;

@end
