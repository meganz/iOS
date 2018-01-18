
#import <UIKit/UIKit.h>

@interface CustomModalAlertViewController : UIViewController

@property (nonatomic, strong) void (^completion)(void);

@property (nonatomic)  NSString *image;
@property (nonatomic)  NSString *viewTitle;
@property (nonatomic)  NSString *detail;
@property (nonatomic)  NSString *boldInDetail;
@property (nonatomic)  NSString *action;
@property (nonatomic)  NSString *dismiss;

@end
