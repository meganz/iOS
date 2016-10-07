#import "MEGAChatSdk.h"
#import "DelegateMEGAChatRequestListener.h"

@interface MEGAChatSdk (init)

- (void)freeRequestListener:(DelegateMEGAChatRequestListener *)delegate;
- (megachat::MegaChatApi *)getCPtr;

@end
