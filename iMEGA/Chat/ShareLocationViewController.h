
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGAChatRoom;
@class MEGAChatMessage;

@protocol ShareLocationViewControllerDelegate <NSObject>

- (void)locationMessage:(MEGAChatMessage *)message editing:(BOOL)editing;

@end

@interface ShareLocationViewController : UIViewController

@property (nonatomic) MEGAChatRoom *chatRoom;
@property (nonatomic) MEGAChatMessage *editMessage;
@property (nonatomic, weak) id<ShareLocationViewControllerDelegate> shareLocationViewControllerDelegate;

@end

NS_ASSUME_NONNULL_END
