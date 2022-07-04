#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@class EndCallDialog;

@interface GroupChatDetailsViewController : UIViewController

@property (nonatomic, strong) MEGAChatRoom *chatRoom;
@property (nonatomic, strong) EndCallDialog *endCallDialog;


- (void)reloadData;

@end
