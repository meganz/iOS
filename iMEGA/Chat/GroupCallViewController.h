
#import <UIKit/UIKit.h>
#import "CallType.h"

@class MEGAChatRoom, MEGACallManager, MEGAChatCall;

@interface GroupCallViewController : UIViewController

@property (nonatomic, strong) MEGACallManager *megaCallManager;
@property (nonatomic) CallType callType;
@property (nonatomic) BOOL videoCall;
@property (nonatomic, strong) MEGAChatRoom *chatRoom;
@property (nonatomic) uint64_t callId;

- (void)tapOnVideoCallkitWhenDeviceIsLocked;

@end
