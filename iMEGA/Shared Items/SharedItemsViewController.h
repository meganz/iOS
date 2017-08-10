#import <UIKit/UIKit.h>

@interface SharedItemsViewController : UIViewController

@property (nonatomic, strong) MEGAUser *user;

- (void)selectSegment:(NSUInteger)index;

@end
