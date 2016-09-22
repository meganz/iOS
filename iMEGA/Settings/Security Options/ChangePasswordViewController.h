#import <UIKit/UIKit.h>

@interface ChangePasswordViewController : UIViewController

typedef NS_ENUM(NSUInteger, ChangeType) {
    ChangeTypePassword = 0,
    ChangeTypeEmail
};

@property (nonatomic) ChangeType changeType;

@end
