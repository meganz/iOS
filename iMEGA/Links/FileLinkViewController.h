#import <UIKit/UIKit.h>

@interface FileLinkViewController : UIViewController

@property (nonatomic, strong) NSString *fileLinkString;

@property (nonatomic, strong) MEGARequest *request;
@property (nonatomic, strong) MEGAError *error;

@end
