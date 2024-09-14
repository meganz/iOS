#import "EmptyStateView.h"

#import "NSString+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface EmptyStateView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewYDefaultConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewYTimelineConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewYHomeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewYHomePlusBannerConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomStackViewTopCompactConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomStackViewTopRegularConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topStackViewCenterConstraint;

@property (nullable, weak, nonatomic) IBOutlet UIView *audioPlayerShownView;

@property (nonatomic) BOOL isTimeline;

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

- (UIView *)initWithImage:(nullable UIImage *)image
                    title:(nullable NSString *)title
              description:(nullable NSString *)description
              buttonTitle:(nullable NSString *)buttonTitle {
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

- (UIView *)initForHomeWithImage:(nullable UIImage *)image
                           title:(nullable NSString *)title
                     description:(nullable NSString *)description
                     buttonTitle:(nullable NSString *)buttonTitle {
    self = [self initWithImage:image title:title description:description buttonTitle:buttonTitle];
    
    [NSLayoutConstraint deactivateConstraints:@[self.imageViewYDefaultConstraint]];
    [NSLayoutConstraint activateConstraints:@[self.imageViewYHomeConstraint]];
    
    return self;
}

- (UIView *)initForTimelineWithImage:(nullable UIImage *)image
                    title:(nullable NSString *)title
              description:(nullable NSString *)description
              buttonTitle:(nullable NSString *)buttonTitle {
    self = [self initWithImage:image title:title description:description buttonTitle:buttonTitle];
    
    self.isTimeline = true;
    
    return self;
}

- (void)enableTimelineLayoutConstraint {
    self.imageViewYDefaultConstraint.active = NO;
    self.imageViewYTimelineConstraint.active = YES;
}

- (void)adjustLayoutWhenThereIsNoImage {
    self.imageViewYDefaultConstraint.active = NO;
    self.bottomStackViewTopCompactConstraint.active = NO;
    self.bottomStackViewTopRegularConstraint.active = NO;
    self.topStackViewCenterConstraint.active = YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
    
#ifdef MAIN_APP_TARGET
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bottomViewVisibility) name:MEGAAudioPlayerShouldUpdateContainerNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(homeChangedHeight:) name:MEGAHomeChangedHeightNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(bannerChangedHomeHeight:) name:MEGABannerChangedHomeHeightNotification object:nil];
#endif
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.isTimeline) {
        [self updateLayoutForTimeline];
    }
    
    if (self.imageView.image == nil && !self.topStackViewCenterConstraint.active) {
        [self adjustLayoutWhenThereIsNoImage];
    }
}

- (void)dealloc {
#ifdef MAIN_APP_TARGET
    [NSNotificationCenter.defaultCenter removeObserver:self];
#endif
}

#pragma mark - Private

- (void)updateAppearance {
    [self designTokenColors];
    [self.button mnz_setupPrimary:self.traitCollection];
}

- (void)bottomViewVisibility {
#ifdef MAIN_APP_TARGET
    self.audioPlayerShownView.hidden = ![AudioPlayerManager.shared isPlayerAlive];
#endif
}

#ifdef MAIN_APP_TARGET
- (void)homeChangedHeight:(NSNotification *)notification {
    BOOL homeChangedHeight = [[notification.userInfo objectForKey:notification.name] boolValue];
    if (homeChangedHeight) {
        [NSLayoutConstraint deactivateConstraints:@[self.imageViewYDefaultConstraint, self.imageViewYHomePlusBannerConstraint]];
        [NSLayoutConstraint activateConstraints:@[self.imageViewYHomeConstraint]];
    } else {
        [NSLayoutConstraint deactivateConstraints:@[self.imageViewYHomeConstraint, self.imageViewYHomePlusBannerConstraint]];
        [NSLayoutConstraint activateConstraints:@[self.imageViewYDefaultConstraint]];
    }
}

- (void)bannerChangedHomeHeight:(NSNotification *)notification {
    BOOL bannerChangedHomeHeight = [[notification.userInfo objectForKey:notification.name] boolValue];
    if (bannerChangedHomeHeight) {
        [NSLayoutConstraint deactivateConstraints:@[self.imageViewYDefaultConstraint, self.imageViewYHomeConstraint]];
        [NSLayoutConstraint activateConstraints:@[self.imageViewYHomePlusBannerConstraint]];
    } else {
        [NSLayoutConstraint deactivateConstraints:@[self.imageViewYDefaultConstraint, self.imageViewYHomePlusBannerConstraint]];
        [NSLayoutConstraint activateConstraints:@[self.imageViewYHomeConstraint]];
    }
}
#endif

@end
