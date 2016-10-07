#import "MEGAChatError.h"
#import "megachatapi.h"

@interface MEGAChatError (init)

- (instancetype)initWithMegaChatError:(megachat::MegaChatError *)megaChatError cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatError *)getCPtr;

@end
