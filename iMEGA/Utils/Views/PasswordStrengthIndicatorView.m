
#import "PasswordStrengthIndicatorView.h"

@interface PasswordStrengthIndicatorView ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *strengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *strengthDescriptionLabel;

@end

@implementation PasswordStrengthIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (void)customInit {
    self.customView = [[[NSBundle mainBundle] loadNibNamed:@"PasswordStrengthIndicatorView" owner:self options:nil] firstObject];
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.strengthLabel.textColor = UIColor.mnz_label;
    [self.strengthLabel sizeToFit];
}

#pragma mark - Public

- (void)updateViewWithPasswordStrength:(PasswordStrength)passwordStrength updateDescription:(BOOL)updateDescription {
    switch (passwordStrength) {
        case PasswordStrengthVeryWeak:
            self.imageView.image = [UIImage imageNamed:@"indicatorVeryWeak"];
            self.strengthLabel.text = NSLocalizedString(@"veryWeak", @"Label displayed during checking the strength of the password introduced. Represents Very Weak security");
            self.strengthLabel.textColor = UIColor.mnz_redError;
            if (updateDescription) {
                self.strengthDescriptionLabel.text = NSLocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthWeak:
            self.imageView.image = [UIImage imageNamed:@"indicatorWeak"];
            self.strengthLabel.text = NSLocalizedString(@"weak", @"");
            self.strengthLabel.textColor = [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0 alpha:1.0];
            if (updateDescription) {
                self.strengthDescriptionLabel.text = NSLocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthMedium:
            self.imageView.image = [UIImage imageNamed:@"indicatorMedium"];
            self.strengthLabel.text = NSLocalizedString(@"PasswordStrengthMedium", @"Label displayed during checking the strength of the password introduced. Represents Medium security");
            self.strengthLabel.textColor = UIColor.systemGreenColor;
            if (updateDescription) {
                self.strengthDescriptionLabel.text = NSLocalizedString(@"passwordMedium", @"");
            }
            break;
            
        case PasswordStrengthGood:
            self.imageView.image = [UIImage imageNamed:@"indicatorGood"];
            self.strengthLabel.text = NSLocalizedString(@"good", @"");
            self.strengthLabel.textColor = [UIColor colorWithRed:18.0/255.0 green:210.0/255.0 blue:56.0/255.0 alpha:1.0];
            if (updateDescription) {
                self.strengthDescriptionLabel.text = NSLocalizedString(@"passwordGood", @"");
            }
            break;
            
        case PasswordStrengthStrong:
            self.imageView.image = [UIImage imageNamed:@"indicatorStrong"];
            self.strengthLabel.text = NSLocalizedString(@"strong", @"Label displayed during checking the strength of the password introduced. Represents Strong security");
            self.strengthLabel.textColor = [UIColor mnz_blueForTraitCollection:self.traitCollection];
            if (updateDescription) {
                self.strengthDescriptionLabel.text = NSLocalizedString(@"passwordStrong", @"");
            }
            break;
    }
}

@end
