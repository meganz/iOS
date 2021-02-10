


@interface MEGAPauseTransferRequestDelegate : NSObject

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
