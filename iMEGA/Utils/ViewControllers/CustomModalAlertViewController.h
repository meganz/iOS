
#import <UIKit/UIKit.h>

@interface CustomModalAlertViewController : UIViewController

@property (nonatomic, strong) void (^completion)(void);
@property (nonatomic, strong) void (^onDismiss)(void);
@property (nonatomic, strong) void (^onBonus)(void);

@property (nonatomic) UIImage *image;
@property (getter=shouldRoundImage) BOOL roundImage;
@property (nonatomic) NSString *viewTitle;
@property (nonatomic) NSString *detail;
@property (nonatomic) NSString *boldInDetail;
@property (nonatomic) NSString *action;
@property (nonatomic) UIColor *actionColor;
@property (nonatomic) NSString *dismiss;
@property (nonatomic) UIColor *dismissColor;
@property (nonatomic) NSString *bonus;

@end
