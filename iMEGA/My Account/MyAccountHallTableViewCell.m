
#import "MyAccountHallTableViewCell.h"

@implementation MyAccountHallTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor mnz_grayF7F7F7];
        self.selectedBackgroundView = view;
        
        self.pendingView.backgroundColor = [UIColor mnz_redFF4D52];
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

@end
