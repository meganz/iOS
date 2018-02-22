#import "SharedItemsTableViewCell.h"

@implementation SharedItemsTableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 104, 0, 0)];
    } else {
        [self setSeparatorInset:UIEdgeInsetsMake(0, 64, 0, 0)];
    }
}

@end
