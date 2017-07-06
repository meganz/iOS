
#import <UIKit/UIKit.h>

@interface LoginRequiredViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, copy) void (^cancelCompletion)(void);

@end
