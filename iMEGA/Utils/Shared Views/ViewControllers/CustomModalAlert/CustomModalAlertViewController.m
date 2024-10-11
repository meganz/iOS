#import "CustomModalAlertViewController.h"

#import "AchievementsViewController.h"
#import "CopyableLabel.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

#import "UIApplication+MNZCategory.h"
#import "UIImage+GKContact.h"

@interface CustomModalAlertViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *firstButton;
@property (weak, nonatomic) IBOutlet UIButton *secondButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet CopyableLabel *linkLabel;

@property (nonatomic) MEGAPresentationManager *presentationManager;

@end

@implementation CustomModalAlertViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    self.presentationManager = MEGAPresentationManager.new;
    self.transitioningDelegate = self.presentationManager;
    self.modalPresentationStyle = UIModalPresentationCustom;
    return self;
}

#pragma mark - Lifecycle
- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    parent.view.backgroundColor = [UIColor.primaryTextColor colorWithAlphaComponent:0.3];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.viewModel) {
        [self.viewModel onViewDidLoad];
    }
    
    [self configUIAppearance];
    
    if (self.image) {
        self.imageView.image = self.image;
        if (self.shouldRoundImage) {
            self.imageView.layer.cornerRadius = (self.imageView.image.size.height / 4);
            self.imageView.clipsToBounds = YES;
        }
    }
    
    self.titleLabel.text = self.viewTitle;
    
    [self setDetailLabelText:self.detail];

    if (self.detailTapGestureRecognizer) {
        self.detailLabel.userInteractionEnabled = YES;
        [self.detailLabel addGestureRecognizer:self.detailTapGestureRecognizer];
    }
    
    if (self.firstButtonStyle == MEGACustomButtonStyleNone) {
        self.firstButtonStyle = MEGACustomButtonStylePrimary;
    }
    
    if (self.firstButtonTitle) {
        [self.firstButton setTitle:self.firstButtonTitle forState:UIControlStateNormal];
    } else {
        self.firstButton.hidden = YES;
    }
    
    if (self.dismissButtonStyle == MEGACustomButtonStyleNone) {
        self.dismissButtonStyle = MEGACustomButtonStyleCancel;
    }
    
    if (self.dismissButtonTitle) {
        [self.dismissButton setTitle:self.dismissButtonTitle forState:UIControlStateNormal];
    } else {
        self.dismissButton.hidden = YES;
    }
    
    if (self.secondButtonTitle) {
        [self.secondButton setTitle:self.secondButtonTitle forState:UIControlStateNormal];
    } else {
        self.secondButton.hidden = YES;
    }
    
    if (self.link) {
        self.linkView.layer.borderColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.1] CGColor];
        self.linkLabel.text = self.link;
    } else {
        self.linkView.hidden = YES;
    }
    
    if (self.detailAttributedTextWithLink) {
        [self updateDetailAttributedTextWithLink:self.detailAttributedTextWithLink];
    }
    
    self.closeButton.hidden = !self.isShowCloseButton;
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (void)setDetailLabelText:(NSString*)detail {
    self.detailTextView.hidden = YES;
    
    if (self.detailAttributed) {
        self.detailLabel.attributedText = self.detailAttributed;
    } else if (self.boldInDetail) {
        NSRange boldRange = [detail rangeOfString:self.boldInDetail];
        
        NSMutableAttributedString *detailAttributedString = [[NSMutableAttributedString alloc] initWithString:detail];
        
        [detailAttributedString beginEditing];
        [detailAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleFootnote weight:UIFontWeightMedium] range:boldRange];
        
        [detailAttributedString endEditing];
        self.detailLabel.attributedText = detailAttributedString;
    } else if (self.monospaceDetail) {
        NSRange monospaceRange = [detail rangeOfString:self.monospaceDetail];
        
        NSMutableAttributedString *detailAttributedString = [[NSMutableAttributedString alloc] initWithString:detail];
        
        [detailAttributedString beginEditing];
        [detailAttributedString addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote] range:monospaceRange];
        
        [detailAttributedString endEditing];
        self.detailLabel.attributedText = detailAttributedString;
    } else {
        self.detailLabel.text = detail;
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.mainView.backgroundColor = [UIColor pageBackgroundColor];
    
    self.linkView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    
#ifdef MAIN_APP_TARGET
    if (self.detailAttributed) {
        self.detailLabel.attributedText = self.detailAttributed;
    }
#endif
    
    [self.firstButton mnz_setup:self.firstButtonStyle traitCollection:self.traitCollection];
    [self.secondButton mnz_setupSecondary:self.traitCollection];
    
    [self.dismissButton mnz_setup:self.dismissButtonStyle traitCollection:self.traitCollection];
}

- (void)configUIAppearance {
    self.mainView.layer.shadowColor = [self mainViewShadowColor].CGColor;
    self.mainView.layer.shadowOffset = CGSizeMake(0, 1);
    self.mainView.layer.shadowOpacity = 0.15;
    
    self.firstButton.titleLabel.numberOfLines = 2;
    self.firstButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.firstButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

#pragma mark - IBActions

- (IBAction)firstButtonTouchUpInside:(UIButton *)sender {
    if (self.viewModel) [self.viewModel firstButtonTapped];
    if (self.firstCompletion) self.firstCompletion();
}

- (IBAction)closeButtonTouchUpInside:(UIButton *)sender {
    [self dismissView];
}

- (IBAction)dismissTouchUpInside:(UIButton *)sender {
    [self dismissView];
}

- (void)dismissView {
    if (self.dismissCompletion) {
        self.dismissCompletion();
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)secondButtonTouchUpInside:(UIButton *)sender {
    if (self.secondCompletion) {
        self.secondCompletion();
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            achievementsVC.enableCloseBarButton = YES;
            UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:achievementsVC];
            [UIApplication.mnz_presentingViewController presentViewController:navigation animated:YES completion:nil];
        }];
    }
}

@end
