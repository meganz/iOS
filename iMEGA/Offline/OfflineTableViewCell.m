#import "OfflineTableViewCell.h"

@implementation OfflineTableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 100, 0, 0);
            [self layoutIfNeeded];
        }];
    } else {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
            [self layoutIfNeeded];
        }];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        view.userInteractionEnabled = NO;
        self.selectedBackgroundView = view;
    }
}

@end
