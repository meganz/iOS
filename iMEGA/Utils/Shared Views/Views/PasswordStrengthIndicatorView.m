#import "PasswordStrengthIndicatorView.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@interface PasswordStrengthIndicatorView ()

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
    self.strengthLabel.textColor = [self textColor];
    [self.strengthLabel sizeToFit];
    
    self.backgroundColor = self.customView.backgroundColor = [UIColor pageBackgroundColor];
}

#pragma mark - Public

- (void)updateViewWithPasswordStrength:(PasswordStrength)passwordStrength updateDescription:(BOOL)updateDescription {
    self.strengthLabel.textColor = [self strengthLabeColorWith:passwordStrength];
    [self setStrengthImageViewTintColorWith:passwordStrength];
    
    switch (passwordStrength) {
        case PasswordStrengthVeryWeak:
            self.imageView.image = [UIImage imageNamed: @"indicatorVeryWeak_semantic"];
            self.strengthLabel.text = LocalizedString(@"veryWeak", @"Label displayed during checking the strength of the password introduced. Represents Very Weak security");
            
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthWeak:
            self.imageView.image = [UIImage imageNamed: @"indicatorWeak_semantic"];
            self.strengthLabel.text = LocalizedString(@"weak", @"");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthMedium:
            self.imageView.image = [UIImage imageNamed: @"indicatorMedium_semantic"];
            self.strengthLabel.text = LocalizedString(@"PasswordStrengthMedium", @"Label displayed during checking the strength of the password introduced. Represents Medium security");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordMedium", @"");
            }
            break;
            
        case PasswordStrengthGood:
            self.imageView.image = [UIImage imageNamed: @"indicatorGood_Semantic"];
            self.strengthLabel.text = LocalizedString(@"good", @"");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordGood", @"");
            }
            break;
            
        case PasswordStrengthStrong:
            self.imageView.image = [UIImage imageNamed: @"indicatorStrong_Semantic"];
            self.strengthLabel.text = LocalizedString(@"strong", @"Label displayed during checking the strength of the password introduced. Represents Strong security");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordStrong", @"");
            }
            break;
    }
}

@end
