
#import "MyAccountHallTableViewCell.h"

#import "MEGA-Swift.h"

@implementation MyAccountHallTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupCell];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self setupCell];
}

#pragma mark - Private

- (void)setupCell {
    self.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    
    self.detailLabel.text = @"";
    self.detailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.pendingView.backgroundColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    self.pendingLabel.textColor = UIColor.whiteColor;
    
    [self layoutPendingView];
}

@end
