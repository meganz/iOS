#import <UIKit/UIKit.h>

@interface VerifyCredentialsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *myCredentialsHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactHeaderLabel;
@property (nonatomic, getter=isVerifyContactForSharedItem) BOOL verifyContactForSharedItem;
@property (nonatomic, getter=isIncomingSharedItem) BOOL incomingSharedItem;

@property (strong, nonatomic) MEGAUser *user;
@property (nonatomic, copy) NSString *userName;

typedef void (^CompletionBlock)(void);
@property (nonatomic, copy) CompletionBlock statusUpdateCompletionBlock;

- (void)setContactVerificationWithIncomingSharedItem:(BOOL)isIncomingSharedItem;

@end
