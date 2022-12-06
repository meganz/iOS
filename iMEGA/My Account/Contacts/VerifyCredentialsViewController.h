#import <UIKit/UIKit.h>

@interface VerifyCredentialsViewController : UIViewController

@property (strong, nonatomic) MEGAUser *user;
@property (nonatomic, copy) NSString *userName;

typedef void (^CompletionBlock)(void);
@property (nonatomic, copy) CompletionBlock statusUpdateCompletionBlock;

@end
