
#import "MEGABaseRequestDelegate.h"

@interface MEGAExportRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks;

@end
