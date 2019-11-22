
#import "EmptyStateView.h"

#import "NSString+MNZCategory.h"

@interface EmptyStateView ()

@property (nullable, weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nullable, weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nullable, weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation EmptyStateView

#pragma mark - Init

- (UIView *)initWithImage:(UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle {
    self = [super init];
    if (self) {
        self = [NSBundle.mainBundle loadNibNamed:@"EmptyStateView" owner:self options:nil].firstObject;
        
        self.imageView.image = image;
        self.titleLabel.text = title;
        if (description == nil || description.mnz_isEmpty) {
            self.descriptionLabel.hidden = YES;
        } else {
            self.descriptionLabel.text = description;
        }
        
        if (buttonTitle == nil || buttonTitle.mnz_isEmpty) {
            self.button.hidden = YES;
        } else {
            [self.button setTitle:buttonTitle forState:UIControlStateNormal];
        }
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateUI];
        }
    }
}

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateUI];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)updateUI {
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesColorForTraitCollection:self.traitCollection];
    
    [self.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.button.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    self.button.layer.shadowColor = UIColor.blackColor.CGColor;
}

@end
