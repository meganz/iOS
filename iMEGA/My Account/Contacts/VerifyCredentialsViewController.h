#import <UIKit/UIKit.h>

@interface VerifyCredentialsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *myCredentialsHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactHeaderLabel;
@property (weak, nonatomic) IBOutlet UIView *incomingItemWarningView;
@property (nonatomic, getter=isVerifyContactForSharedItem) BOOL verifyContactForSharedItem;
@property (nonatomic, getter=isIncomingSharedItem) BOOL incomingSharedItem;
@property (nonatomic, getter=isShowIncomingItemWarningView) BOOL showIncomingItemWarningView;

@property (strong, nonatomic) MEGAUser *user;
@property (nonatomic, copy) NSString *userName;

typedef void (^CompletionBlock)(void);
@property (nonatomic, copy) CompletionBlock statusUpdateCompletionBlock;

- (void)setContactVerificationWithIncomingSharedItem:(BOOL)isIncomingSharedItem
                       isShowIncomingItemWarningView:(BOOL)isShowIncomingItemWarningView;

@end
