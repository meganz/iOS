#import "OfflineTableViewCell.h"

@implementation OfflineTableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
    } else {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
    }
}

@end
