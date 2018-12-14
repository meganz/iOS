#import <UIKit/UIKit.h>

@interface FileLinkViewController : UIViewController

@property (nonatomic, strong) NSString *publicLinkString;
@property (nonatomic, strong) NSString *linkEncryptedString;

@property (nonatomic, strong) MEGARequest *request;
@property (nonatomic, strong) MEGAError *error;

@end
