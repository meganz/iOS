
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

typedef NS_ENUM(NSUInteger, CallType) {
    CallTypeIncoming,
    CallTypeOutgoing
};

@interface CallViewController : UIViewController

@property (nonatomic) uint64_t chatId;
@property (nonatomic) BOOL videoCall;
@property (nonatomic) CallType callType;

@end
