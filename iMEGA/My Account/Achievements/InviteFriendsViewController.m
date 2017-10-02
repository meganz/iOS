
#import "InviteFriendsViewController.h"

#import "ZFTokenField.h"

#import "MEGAInviteContactRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIColor+MNZCategory.h"

@interface InviteFriendsViewController () <ZFTokenFieldDataSource, ZFTokenFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIView *inviteYourFriendsView;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsSubtitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *inviteYourFriendsExplanationLabel;

@property (weak, nonatomic) IBOutlet ZFTokenField *tokenField;
@property (weak, nonatomic) IBOutlet UIButton *addContactsButton;

@property (weak, nonatomic) IBOutlet UILabel *inviteButtonUpperLabel;
@property (weak, nonatomic) IBOutlet UIButton *inviteButton;

@property (weak, nonatomic) IBOutlet UIView *howItWorksView;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksMainLabel;
@property (weak, nonatomic) IBOutlet UILabel *howItWorksSecondaryLabel;

@property (nonatomic, strong) NSMutableArray *tokens;

@end

@implementation InviteFriendsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(howItWorksTapped)];
    self.inviteYourFriendsView.gestureRecognizers = @[tapGestureRecognizer];
    self.inviteYourFriendsTitleLabel.text = AMLocalizedString(@"inviteYourFriends", @"Indicating text for when 'you invite your friends'");
    self.inviteYourFriendsSubtitleLabel.text = AMLocalizedString(@"inviteFriendsAndGetForEachReferral", @"Subtitle shown under the label 'Invite your friends' explaining the reward you will get after each referral");
    
    self.inviteYourFriendsExplanationLabel.text = AMLocalizedString(@"inviteYourFriendsExplanation", @"Text shown to explain how and where you can invite friends");
    
    self.tokens = [NSMutableArray array];
    self.tokenField.dataSource = self;
    self.tokenField.delegate = self;
    self.tokenField.textField.placeholder = AMLocalizedString(@"enterEmailAddress", @"Placeholder shown to give a hint of what you have to write in it. In this case email addresses");
    [self.tokenField reloadData];
    
    self.inviteButtonUpperLabel.text = @"";
    [self.inviteButton setTitle:AMLocalizedString(@"invite", @"A button on a dialog which invites a contact to join MEGA.") forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapGestureRecognizer2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(howItWorksTapped)];
    self.howItWorksView.gestureRecognizers = @[tapGestureRecognizer2];
    self.howItWorksLabel.text = AMLocalizedString(@"howItWorks", @"");
    self.howItWorksMainLabel.text = [AMLocalizedString(@"howItWorksMain", @"")  mnz_removeWebclientFormatters];
    NSString *secondaryLabelString = AMLocalizedString(@"howItWorksSecondary", @"");
    secondaryLabelString = [secondaryLabelString stringByAppendingString:@"\n\n"];
    secondaryLabelString = [secondaryLabelString stringByAppendingString:AMLocalizedString(@"howItWorksTertiary", @"A message which is shown once someone has invited a friend as part of the achievements program.")];
    self.howItWorksSecondaryLabel.text = secondaryLabelString;
}

#pragma mark - Private

- (void)howItWorksTapped {
    [self.scrollView scrollRectToVisible:self.howItWorksView.frame animated:YES];
}

#pragma mark - IBActions

- (IBAction)addContactsTouchUpInside:(UIButton *)sender {
    
}

- (IBAction)inviteTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGAInviteContactRequestDelegate *inviteContactRequestDelegate = [[MEGAInviteContactRequestDelegate alloc] initWithNumberOfRequests:self.tokens.count];
        for (NSString *email in self.tokens) {
            [[MEGASdkManager sharedMEGASdk] inviteContactWithEmail:email message:@"" action:MEGAInviteActionAdd delegate:inviteContactRequestDelegate];
        }
    }
}

#pragma mark - ZFTokenFieldDataSource

- (CGFloat)lineHeightForTokenInField:(ZFTokenField *)tokenField {
    return 27.0f;
}

- (NSUInteger)numberOfTokenInField:(ZFTokenField *)tokenField {
    return self.tokens.count;
}

- (UIView *)tokenField:(ZFTokenField *)tokenField viewForTokenAtIndex:(NSUInteger)index {
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"EmailTokenView" owner:nil options:nil];
    UIView *view = nibContents[0];
    UILabel *label = (UILabel *)[view viewWithTag:1];
    label.text = self.tokens[index];
    CGSize size = [label sizeThatFits:CGSizeMake(1000.0f, 27.0f)];
    view.frame = CGRectMake(0, 0, size.width + (8.0f * 2.0f), 27.0f);
    
    return view;
}

#pragma mark - ZFTokenFieldDelegate

- (CGFloat)tokenMarginInTokenInField:(ZFTokenField *)tokenField {
    return 10.0f;
}

- (void)tokenField:(ZFTokenField *)tokenField didReturnWithText:(NSString *)text {
    if (text.length == 0 || text.mnz_isEmpty) {
        return;
    }
    
    if (text.mnz_isValidEmail) {
        self.tokenField.textField.textColor = [UIColor mnz_black333333];
        
        self.inviteButtonUpperLabel.text = @"";
        self.inviteButtonUpperLabel.textColor = [UIColor mnz_gray999999];
        
        [self.tokens addObject:text];
        [tokenField reloadData];
        
        self.inviteButton.backgroundColor = [UIColor mnz_redF0373A];
    } else {
        self.tokenField.textField.textColor = [UIColor mnz_redD90007];
        
        self.inviteButtonUpperLabel.text = AMLocalizedString(@"theEmailAddressFormatIsInvalid", @"Add contacts and share dialog error message when user try to add wrong email address");
        self.inviteButtonUpperLabel.textColor = [UIColor mnz_redD90007];
    }
}

- (void)tokenField:(ZFTokenField *)tokenField didRemoveTokenAtIndex:(NSUInteger)index {
    [self.tokens removeObjectAtIndex:index];
    
    if (self.tokens.count == 0) {
        self.inviteButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

@end
