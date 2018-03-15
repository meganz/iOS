#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

@interface PreviewDocumentViewController : UIViewController

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) MEGASdk *api;
@property (nonatomic, strong) NSString *previewDocumentPath;

- (void)doneTapped;

@end
