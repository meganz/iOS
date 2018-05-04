
#import "MEGAMessageDialogView.h"

@implementation MEGAMessageDialogView

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (IBAction)didTapButton:(UIButton *)sender {
    [self.delegate dialogView:self chosedOption:(MEGAMessageDialogOption)sender.tag];
}

@end
