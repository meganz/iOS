#import <UIKit/UIKit.h>

@class MyAvatarManager;

NS_ASSUME_NONNULL_BEGIN

@interface SharedItemsViewController : UIViewController

@property (nonatomic, strong, nullable) MyAvatarManager *myAvatarManager;

- (void)selectSegment:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
