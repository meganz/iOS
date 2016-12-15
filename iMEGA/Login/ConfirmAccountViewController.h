#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"


@interface ConfirmAccountViewController : UIViewController 

typedef NS_ENUM(NSUInteger, ConfirmType) {
    ConfirmTypeAccount = 0,
    ConfirmTypeEmail,
    ConfirmTypeCancelAccount
};

@property (nonatomic) ConfirmType confirmType;

@property (strong, nonatomic) NSString *confirmationLinkString;
@property (strong, nonatomic) NSString *emailString;

@end
