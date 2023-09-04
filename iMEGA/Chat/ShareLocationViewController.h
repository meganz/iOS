#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGAChatRoom;
@class MEGAChatMessage;

@interface ShareLocationViewController : UIViewController

@property (nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic) MEGAChatMessage *editMessage;

@end

NS_ASSUME_NONNULL_END
