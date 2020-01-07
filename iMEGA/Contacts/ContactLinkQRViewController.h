
#import <UIKit/UIKit.h>

#import "ContacLinkQRType.h"

@protocol ContactLinkQRViewControllerDelegate <NSObject>

- (void)emailForScannedQR:(NSString *)email;

@end

@interface ContactLinkQRViewController : UIViewController

@property (weak, nonatomic) id<ContactLinkQRViewControllerDelegate> contactLinkQRDelegate;

@property (nonatomic) BOOL scanCode;
@property (nonatomic) ContactLinkQRType contactLinkQRType;

@end
