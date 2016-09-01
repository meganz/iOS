#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SharedItemsMode) {
    SharedItemsModeDefault = 0,
    SharedItemsModeInSharesForUser
};

@interface SharedItemsViewController : UIViewController

@property (nonatomic) SharedItemsMode sharedItemsMode;
@property (nonatomic, strong) MEGAUser *user;

@end
