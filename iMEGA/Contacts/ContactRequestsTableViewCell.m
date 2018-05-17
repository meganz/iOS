
#import "ContactRequestsTableViewCell.h"

@implementation ContactRequestsTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor mnz_grayF7F7F7];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

@end
