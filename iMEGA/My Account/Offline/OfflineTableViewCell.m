#import "OfflineTableViewCell.h"
#import "MEGA-Swift.h"

@implementation OfflineTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureImages];
    
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    [self updateAppearance];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = self.subviews.count == 3; // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        self.moreButton.hidden = YES;
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 100, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        self.moreButton.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
            [self layoutIfNeeded];
        }];
    }
}

#pragma mark - Private

- (void)configureImages {
    self.thumbnailPlayImageView.image = [UIImage megaImageWithNamed:@"video_list"];
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreList"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreList"] forState:UIControlStateSelected];
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreList"] forState:UIControlStateHighlighted];
}

- (void)updateAppearance {
    [self configureTokenColors];
}

@end
