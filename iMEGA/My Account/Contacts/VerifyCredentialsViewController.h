#import <UIKit/UIKit.h>

@interface VerifyCredentialsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *myCredentialsHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactHeaderLabel;

@property (weak, nonatomic) IBOutlet UIView *myCredentialsTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *myCredentialsView;
@property (weak, nonatomic) IBOutlet UIView *myCredentialsSubView;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;

@property (nonatomic, getter=isVerifyContactForSharedItem) BOOL verifyContactForSharedItem;
@property (nonatomic, getter=isIncomingSharedItem) BOOL incomingSharedItem;

@property (strong, nonatomic) MEGAUser *user;
@property (nonatomic, copy) NSString *userName;

typedef void (^CompletionBlock)(void);
@property (nonatomic, copy) CompletionBlock statusUpdateCompletionBlock;

- (void)setContactVerification:(BOOL)isIncomingSharedItem;

@end
