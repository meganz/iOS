
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
@property (weak, nonatomic) IBOutlet UIImageView *qrImageView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (nonatomic) MEGAContactLinkCreateRequestDelegate *contactLinkCreateDelegate;

@property (weak, nonatomic) id<ContactLinkQRViewControllerDelegate> contactLinkQRDelegate;

@property (nonatomic, strong, nullable) ContextMenuManager *contextMenuManager;
@property (nonatomic) BOOL scanCode;
@property (nonatomic) ContactLinkQRType contactLinkQRType;

@end

NS_ASSUME_NONNULL_END
