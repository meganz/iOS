
#import "MyAccountHallTableViewCell.h"

@implementation MyAccountHallTableViewCell

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView = view;
        
        self.pendingView.backgroundColor = UIColor.mnz_redMain;
    }
}

@end
