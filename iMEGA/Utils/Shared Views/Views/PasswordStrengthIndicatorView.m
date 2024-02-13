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
    
    if (UIColor.isDesignTokenEnabled) {
        self.backgroundColor = self.customView.backgroundColor = [UIColor pageBackgroundForTraitCollection:self.traitCollection];
    } else {
        self.backgroundColor = self.customView.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Public

- (void)updateViewWithPasswordStrength:(PasswordStrength)passwordStrength updateDescription:(BOOL)updateDescription {
    self.strengthLabel.textColor = [self strengthLabeColorWith:passwordStrength];
    [self setStrengthImageViewTintColorWith:passwordStrength];
    
    switch (passwordStrength) {
        case PasswordStrengthVeryWeak:
            self.imageView.image = [UIImage imageNamed: [UIColor isDesignTokenEnabled] ? @"indicatorVeryWeak_Semantic": @"indicatorVeryWeak"];
            self.strengthLabel.text = LocalizedString(@"veryWeak", @"Label displayed during checking the strength of the password introduced. Represents Very Weak security");
            
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthWeak:
            self.imageView.image = [UIImage imageNamed: [UIColor isDesignTokenEnabled] ? @"indicatorWeak_Semantic" : @"indicatorWeak"];
            self.strengthLabel.text = LocalizedString(@"weak", @"");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordVeryWeakOrWeak", @"");
            }
            break;
            
        case PasswordStrengthMedium:
            self.imageView.image = [UIImage imageNamed: [UIColor isDesignTokenEnabled] ? @"indicatorMedium_Semantic" : @"indicatorMedium"];
            self.strengthLabel.text = LocalizedString(@"PasswordStrengthMedium", @"Label displayed during checking the strength of the password introduced. Represents Medium security");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordMedium", @"");
            }
            break;
            
        case PasswordStrengthGood:
            self.imageView.image = [UIImage imageNamed: [UIColor isDesignTokenEnabled] ? @"indicatorGood_Semantic": @"indicatorGood"];
            self.strengthLabel.text = LocalizedString(@"good", @"");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordGood", @"");
            }
            break;
            
        case PasswordStrengthStrong:
            self.imageView.image = [UIImage imageNamed: [UIColor isDesignTokenEnabled] ? @"indicatorStrong_Semantic" : @"indicatorStrong"];
            self.strengthLabel.text = LocalizedString(@"strong", @"Label displayed during checking the strength of the password introduced. Represents Strong security");
            if (updateDescription) {
                self.strengthDescriptionLabel.text = LocalizedString(@"passwordStrong", @"");
            }
            break;
    }
}

@end
