
NS_ASSUME_NONNULL_BEGIN

@interface MEGAUserAlertList (MNZCategory)

@property (nonatomic, readonly) NSArray<MEGAUserAlert *> *mnz_relevantUserAlertsArray;
@property (nonatomic, readonly) NSUInteger mnz_relevantUnseenCount;

@end

NS_ASSUME_NONNULL_END
