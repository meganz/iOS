
#import "MEGAMessageDialogView.h"

@implementation MEGAMessageDialogView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.titleLabel.text = AMLocalizedString(@"enableRichUrlPreviews", @"Title used on the warning dialog that asks users to enable rich URL previews");
    self.descriptionLabel.text = AMLocalizedString(@"richPreviewsFooter", @"Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs");
    [self.alwaysAcceptButton setTitle:AMLocalizedString(@"alwaysAccept", @"Button title to always accept something") forState:UIControlStateNormal];
    [self.notNowButton setTitle:AMLocalizedString(@"notNow", @"Button title to not accept something for the moment") forState:UIControlStateNormal];
    [self.neverButton setTitle:AMLocalizedString(@"never", @"") forState:UIControlStateNormal];
}

- (IBAction)didTapButton:(UIButton *)sender {
    [self.delegate dialogView:self chosedOption:(MEGAMessageDialogOption)sender.tag];
}

@end
