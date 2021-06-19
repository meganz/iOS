#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

@interface PreviewDocumentViewController : UIViewController

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic) uint64_t nodeHandle;
@property (nonatomic, strong) MEGASdk *api;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic) BOOL isLink;
@property (nonatomic) NSString *fileLink;
@property (nonatomic) BOOL showUnknownEncodeHud;

@end
