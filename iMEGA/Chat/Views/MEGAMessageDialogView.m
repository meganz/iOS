
#import "MEGAMessageDialogView.h"

@implementation MEGAMessageDialogView

- (IBAction)didTapButton:(UIButton *)sender {
    [self.delegate dialogView:self chosedOption:(MEGAMessageDialogOption)sender.tag];
}

@end
