#import <UIKit/UIKit.h>

#import "URLType.h"

@interface ConfirmAccountViewController : UIViewController 

@property (nonatomic) URLType urlType;

@property (strong, nonatomic) NSString *confirmationLinkString;
@property (strong, nonatomic) NSString *emailString;

@end
