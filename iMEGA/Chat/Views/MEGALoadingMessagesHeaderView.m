#import "MEGALoadingMessagesHeaderView.h"

#import "MEGA-Swift.h"

@interface MEGALoadingMessagesHeaderView ()

@property (weak, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UIView *placeholderTwoView;
@property (weak, nonatomic) IBOutlet UIView *placeholderThreeView;
@property (weak, nonatomic) IBOutlet UIView *placeholderFourView;
@property (weak, nonatomic) IBOutlet UIView *placeholderFiveView;
@property (weak, nonatomic) IBOutlet UIView *placeholderSixView;

@end

@implementation MEGALoadingMessagesHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];

    [self updateAppearance];
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

+ (UINib *)nib {
    return [UINib nibWithNibName:@"MEGALoadingMessagesHeaderView" bundle:nil];
}

+ (NSString *)headerReuseIdentifier {
    return @"MEGALoadingMessagesHeaderViewID";
}

- (void)updateAppearance {
    self.loadingView.backgroundColor = UIColor.mnz_background;

    self.placeholderView.backgroundColor = self.placeholderTwoView.backgroundColor = self.placeholderThreeView.backgroundColor = self.placeholderFourView.backgroundColor = self.placeholderFiveView.backgroundColor = self.placeholderSixView.backgroundColor = [UIColor mnz_chatLoadingBubble:self.traitCollection];
}

@end
