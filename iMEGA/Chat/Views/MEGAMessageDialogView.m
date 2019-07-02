
#import "MEGAMessageDialogView.h"

@implementation MEGAMessageDialogView

- (IBAction)didTapButton:(UIButton *)sender {
    [self.delegate dialogView:self didChooseOption:(MEGAMessageDialogOption)sender.tag];
}

@end
