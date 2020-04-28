
#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"
#import "MEGACallManager.h"
#import "CallType.h"

@interface CallViewController : UIViewController

@property (nonatomic, strong) MEGAChatRoom *chatRoom;
@property (nonatomic) BOOL videoCall; // This property may be YES only when answering a video call, when instatiate the view controller from an active call is NO.
@property (nonatomic) CallType callType;
@property (nonatomic, strong) MEGACallManager *megaCallManager;
@property (nonatomic) uint64_t callId;

- (void)tapOnVideoCallkitWhenDeviceIsLocked;

@end
