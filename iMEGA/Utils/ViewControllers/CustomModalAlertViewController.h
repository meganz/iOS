
#import <UIKit/UIKit.h>

@interface CustomModalAlertViewController : UIViewController

@property (nonatomic, strong) void (^firstCompletion)(void);
@property (nonatomic, strong) void (^secondCompletion)(void);
@property (nonatomic, strong) void (^dismissCompletion)(void);

@property (nonatomic) UIImage *image;
@property (getter=shouldRoundImage) BOOL roundImage;
@property (nonatomic) NSString *viewTitle;
@property (nonatomic) NSString *detail;
@property (nonatomic) NSString *boldInDetail;
@property (nonatomic) NSString *firstButtonTitle;
@property (nonatomic) NSString *secondButtonTitle;
@property (nonatomic) NSString *dismissButtonTitle;
@property (nonatomic) NSString *link;

@end
