#import <UIKit/UIKit.h>

@class MyAvatarManager;

@interface SharedItemsViewController : UIViewController

@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic, strong) MyAvatarManager * _Nullable myAvatarManager;

- (void)selectSegment:(NSUInteger)index;

@end
