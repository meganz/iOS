
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MEGAMessageDialogOption) {
    MEGAMessageDialogOptionNever,
    MEGAMessageDialogOptionNotNow,
    MEGAMessageDialogOptionAlwaysAccept
};

@class MEGAMessageDialogView;

@protocol MEGAMessageDialogViewDelegate <NSObject>
- (void)dialogView:(MEGAMessageDialogView *)dialogView chosedOption:(MEGAMessageDialogOption)option;
@end

@interface MEGAMessageDialogView : UIView

@property (weak, nonatomic) IBOutlet UILabel *headingLabel;
@property (weak, nonatomic) IBOutlet UIButton *neverButton;
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;
@property (weak, nonatomic) IBOutlet UIButton *alwaysAcceptButton;

// A delegate usually should be weak to avoid a retain cycle, but in this case the delegate
// would be freed if it is marked as weak. That is the reason why it is not weak.
@property (nonatomic) id<MEGAMessageDialogViewDelegate> delegate;

@end
