#import <UIKit/UIKit.h>

@interface VerifyCredentialsViewController : UIViewController

@property (weak, nonatomic) MEGAUser *user;
@property (weak, nonatomic) NSString *userName;

typedef void (^CompletionBlock)(void);
@property (nonatomic, copy) CompletionBlock statusUpdateCompletionBlock;

@end
