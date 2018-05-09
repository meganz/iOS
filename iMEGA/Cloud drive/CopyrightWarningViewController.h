
#import <UIKit/UIKit.h>

@interface CopyrightWarningViewController : UIViewController

@property (nonatomic) NSArray *nodesToExport;

+ (void)presentGetLinkViewControllerForNodes:(NSArray<MEGANode *> *)nodes inViewController:(UIViewController *)viewController;

@end
