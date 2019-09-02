
#import <UIKit/UIKit.h>

#import "ContacLinkQRType.h"

@protocol ContactLinkQRViewControllerProtocol <NSObject>

- (void)emailForScannedQR:(NSString *)email;

@end

@interface ContactLinkQRViewController : UIViewController

@property (weak, nonatomic) id<ContactLinkQRViewControllerProtocol> contactLinkQRDelegate;

@property (nonatomic) BOOL scanCode;
@property (nonatomic) ContactLinkQRType contactLinkQRType;

@end
