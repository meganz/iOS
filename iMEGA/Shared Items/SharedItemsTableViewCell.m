#import "SharedItemsTableViewCell.h"

@implementation SharedItemsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateAppearance];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = self.subviews.count == 3; // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 98, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 58, 0, 0);
            [self layoutIfNeeded];
        }];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}


@end
