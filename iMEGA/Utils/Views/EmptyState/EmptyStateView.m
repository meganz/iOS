
#import "EmptyStateView.h"

#import "NSString+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface EmptyStateView ()

@property (nullable, weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nullable, weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nullable, weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nullable, weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation EmptyStateView

#pragma mark - Init

+ (UINib *)nib {
    static UINib *_nib;
    
    if (_nib == nil) {
        _nib = [UINib nibWithNibName:@"EmptyStateView" bundle:[NSBundle bundleForClass:[self class]]];
    }
    
    return _nib;
}

- (UIView *)initWithImage:(nullable UIImage *)image title:(nullable NSString *)title description:(nullable NSString *)description buttonTitle:(nullable NSString *)buttonTitle {
    self = [super init];
    if (self) {
        self = [[EmptyStateView nib] instantiateWithOwner:nil options:nil].firstObject;
        
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
            self.button.hidden = NO;
            [self.button setTitle:buttonTitle forState:UIControlStateNormal];
        }
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
      
#ifdef MAIN_APP_TARGET
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bottomViewVisibility) name:MEGAAudioPlayerShouldUpdateContainerNotification object:nil];
#endif
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
#ifdef MAIN_APP_TARGET
    [NSNotificationCenter.defaultCenter removeObserver:self];
#endif
}

#pragma mark - Private

- (void)updateAppearance {
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.button mnz_setupPrimary:self.traitCollection];
    [self bottomViewVisibility];
}

- (void)bottomViewVisibility {
#ifdef MAIN_APP_TARGET
    self.bottomView.hidden = ![AudioPlayerManager.shared isPlayerAlive];
#endif
}

@end
