
#import "MyAccountHallTableViewCell.h"

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
    self.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    
    self.detailLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    
    self.pendingView.backgroundColor = [UIColor mnz_redMainForTraitCollection:self.traitCollection];
    self.pendingLabel.textColor = UIColor.whiteColor;
}


@end
