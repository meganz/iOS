#import <UIKit/UIKit.h>

#import "ContacLinkQRType.h"
#import "MEGAContactLinkCreateRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class ContextMenuManager;

@protocol ContactLinkQRViewControllerDelegate <NSObject>

- (void)emailForScannedQR:(NSString *)email;

@end

@interface ContactLinkQRViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *contactLinkLabel;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *linkCopyButton;

@property (weak, nonatomic) IBOutlet UIView *avatarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskView;
@property (weak, nonatomic) IBOutlet UIView *cameraMaskBorderView;


@property (nonatomic) MEGAContactLinkCreateRequestDelegate *contactLinkCreateDelegate;

@property (weak, nonatomic) id<ContactLinkQRViewControllerDelegate> contactLinkQRDelegate;

@property (nonatomic, strong, nullable) ContextMenuManager *contextMenuManager;
@property (nonatomic) BOOL scanCode;
@property (nonatomic) BOOL queryInProgress;
@property (nonatomic) ContactLinkQRType contactLinkQRType;

@end

typedef NS_ENUM(NSInteger, QRSection) {
    QRSectionMyCode = 0,
    QRSectionScanCode = 1
};

NS_ASSUME_NONNULL_END
