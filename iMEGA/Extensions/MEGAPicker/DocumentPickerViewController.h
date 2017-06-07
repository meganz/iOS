
#import "LTHPasscodeViewController.h"

#import "BrowserViewController.h"
#import "MEGARequestDelegate.h"

@interface DocumentPickerViewController : UIDocumentPickerExtensionViewController <MEGARequestDelegate, MEGATransferDelegate, BrowserViewControllerDelegate, LTHPasscodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *megaLogo;
@property (weak, nonatomic) IBOutlet UITextView *loginText;
@property (weak, nonatomic) IBOutlet UIButton *openMega;
@property (nonatomic) NSString *session;
@property (nonatomic) UIView *privacyView;

@end
