#import "MEGARequestDelegate.h"

@interface MEGAExportRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks;

@end
