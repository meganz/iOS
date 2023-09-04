#import <UIKit/UIKit.h>

@class CountdownTimer;
@interface CustomModalAlertViewController : UIViewController

@property (nonatomic, strong) void (^firstCompletion)(void);
@property (nonatomic, strong) void (^secondCompletion)(void);
@property (nonatomic, strong) void (^dismissCompletion)(void);

@property (weak, nonatomic) IBOutlet UITextView *detailTextView;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (nonatomic) UIImage *image;
@property (getter=shouldRoundImage) BOOL roundImage;
@property (nonatomic) NSString *viewTitle;
@property (getter=isShowCloseButton) BOOL showCloseButton;

@property (nonatomic) NSString *detail;
@property (nonatomic) NSString *boldInDetail;
@property (nonatomic) NSString *monospaceDetail;
@property (nonatomic) NSAttributedString *detailAttributed;
@property (nonatomic) NSAttributedString *detailAttributedTextWithLink;
@property (nonatomic) UITapGestureRecognizer *detailTapGestureRecognizer;

@property (nonatomic) NSString *firstButtonTitle;
@property (nonatomic) NSInteger firstButtonStyle;
@property (nonatomic) NSString *secondButtonTitle;
@property (nonatomic) NSInteger dismissButtonStyle;
@property (nonatomic) NSString *dismissButtonTitle;
@property (nonatomic) NSString *link;

@property (nonatomic, strong) CountdownTimer *countdownTimer;

- (void)setDetailLabelText:(NSString*)detail;

@end
