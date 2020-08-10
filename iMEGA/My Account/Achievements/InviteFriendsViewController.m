
#import "InviteFriendsViewController.h"

#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@interface InviteFriendsViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *inviteYourFriendsView;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsSubtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (weak, nonatomic) IBOutlet UIView *howItWorksView;
@property (weak, nonatomic) IBOutlet UIView *howItWorksTopSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksFirstParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksSecondParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksThirdParagraphLabel;

@end

@implementation InviteFriendsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    
    self.inviteYourFriendsTitleLabel.text = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    self.inviteYourFriendsSubtitleLabel.text = self.inviteYourFriendsSubtitleString;
    
    [self.inviteButton setTitle:AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.") forState:UIControlStateNormal];
    
    self.howItWorksLabel.text = AMLocalizedString(@"howItWorks", @"");
    self.howItWorksFirstParagraphLabel.text = [AMLocalizedString(@"howItWorksMain", @"")  mnz_removeWebclientFormatters];
    self.howItWorksSecondParagraphLabel.text = AMLocalizedString(@"howItWorksSecondary", @"");
    self.howItWorksThirdParagraphLabel.text = AMLocalizedString(@"howItWorksTertiary", @"A message which is shown once someone has invited a friend as part of the achievements program.");
    
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

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.inviteYourFriendsView.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
    self.inviteYourFriendsSubtitleLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.inviteButton mnz_setupPrimary:self.traitCollection];
    
    self.howItWorksView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    self.howItWorksTopSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.howItWorksFirstParagraphLabel.textColor = self.howItWorksSecondParagraphLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    self.howItWorksThirdParagraphLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)inviteTouchUpInside:(UIButton *)sender {
    InviteContactViewController *inviteContactsVC = [[UIStoryboard storyboardWithName:@"InviteContact" bundle:nil] instantiateViewControllerWithIdentifier:@"InviteContactViewControllerID"];
    [self.navigationController pushViewController:inviteContactsVC animated:YES];
}

@end
