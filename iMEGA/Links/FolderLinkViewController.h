#import <UIKit/UIKit.h>

@interface FolderLinkViewController : UIViewController

@property (nonatomic) BOOL isFolderRootNode;
@property (nonatomic, strong) NSString *publicLinkString;
@property (nonatomic, strong) NSString *linkEncryptedString;

@end
