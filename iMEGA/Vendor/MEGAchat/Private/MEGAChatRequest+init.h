#import "MEGAChatRequest.h"
#import "megachatapi.h"

@interface MEGAChatRequest (init)

- (instancetype)initWithMegaChatRequest:(megachat::MegaChatRequest *)megaChatRequest cMemoryOwn:(BOOL)cMemoryOwn;
- (megachat::MegaChatRequest *)getCPtr;

@end
