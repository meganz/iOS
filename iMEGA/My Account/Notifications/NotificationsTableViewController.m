#import "NotificationsTableViewController.h"

#import "UIScrollView+EmptyDataSet.h"

#import "ContactDetailsViewController.h"
#import "ContactsViewController.h"
#import "ContactRequestsViewController.h"
#import "EmptyStateView.h"
#import "Helper.h"
#import "MainTabBarController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGAUserAlert.h"
#import "NotificationTableViewCell.h"
#import "SharedItemsViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface NotificationsTableViewController () <DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, MEGAGlobalDelegate>

@property (nonatomic) NSArray *userAlertsArray;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation NotificationsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    self.navigationItem.title = LocalizedString(@"notifications", @"");
    [self registerCustomCells];
    [self fetchAlerts];
    [self logUserAlertsStatus:self.userAlertsArray];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorColor = [UIColor mnz_separator];
    
    [self setupViewModelForCommandHandling];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self dispatchActionsOnAppear];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [MEGASdk.shared acknowledgeUserAlerts];
    
    [self clearImageLoaderCache];
}

#pragma mark - Private

- (void)configureTypeLabel:(UILabel *)typeLabel forType:(MEGAUserAlertType)type {
    switch (type) {
        case MEGAUserAlertTypeIncomingPendingContactRequest:
        case MEGAUserAlertTypeIncomingPendingContactCancelled:
        case MEGAUserAlertTypeIncomingPendingContactReminder:
        case MEGAUserAlertTypeContactChangeDeletedYou:
        case MEGAUserAlertTypeContactChangeContactEstablished:
        case MEGAUserAlertTypeContactChangeAccountDeleted:
        case MEGAUserAlertTypeContactChangeBlockedYou:
        case MEGAUserAlertTypeUpdatePendingContactIncomingIgnored:
        case MEGAUserAlertTypeUpdatePendingContactIncomingAccepted:
        case MEGAUserAlertTypeUpdatePendingContactIncomingDenied:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingAccepted:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingDenied:
            typeLabel.text = LocalizedString(@"contactsTitle", @"Title of the Contacts section");
            typeLabel.textColor = [UIColor supportSuccessColor];
            break;
            
        case MEGAUserAlertTypeNewShare:
        case MEGAUserAlertTypeDeletedShare:
        case MEGAUserAlertTypeNewShareNodes:
        case MEGAUserAlertTypeRemovedSharesNodes:
            typeLabel.text = LocalizedString(@"shared", @"Title of the tab bar item for the Shared Items section");
            typeLabel.textColor = UIColor.systemOrangeColor;
            break;
            
        case MEGAUserAlertTypePaymentSucceeded:
        case MEGAUserAlertTypePaymentFailed:
            typeLabel.text = LocalizedString(@"Payment info", @"The header of a notification related to payments");
            typeLabel.textColor = [UIColor mnz_red];
            break;
            
        case MEGAUserAlertTypePaymentReminder:
            typeLabel.text = LocalizedString(@"PRO membership plan expiring soon", @"A title for a notification saying the user’s pricing plan will expire soon.");
            typeLabel.textColor = [UIColor mnz_red];
            break;
            
        case MEGAUserAlertTypeTakedown:
            typeLabel.text = LocalizedString(@"Takedown notice", @"The header of a notification indicating that a file or folder has been taken down due to infringement or other reason.");
            typeLabel.textColor = [UIColor mnz_red];
            break;
            
        case MEGAUserAlertTypeTakedownReinstated:
            typeLabel.text = LocalizedString(@"Takedown reinstated", @"The header of a notification indicating that a file or folder that was taken down has now been restored due to a successful counter-notice.");
            typeLabel.textColor = [UIColor mnz_red];
            break;
            
        case MEGAUserAlertTypeScheduledMeetingNew:
        case MEGAUserAlertTypeScheduledMeetingUpdated:
        case MEGAUserAlertTypeScheduledMeetingDeleted:
            typeLabel.text = LocalizedString(@"inapp.notifications.meetings.header", @"The header of a notification that is related to scheduled meetings");
            typeLabel.textColor = [UIColor mnz_red];
            break;
            
        default:
            typeLabel.text = nil;
            break;
    }
}

- (void)configureHeadingLabel:(UILabel *)headingLabel forAlert:(MEGAUserAlert *)userAlert {
    switch (userAlert.type) {
        case MEGAUserAlertTypeIncomingPendingContactRequest:
        case MEGAUserAlertTypeIncomingPendingContactCancelled:
        case MEGAUserAlertTypeIncomingPendingContactReminder:
        case MEGAUserAlertTypeContactChangeDeletedYou:
        case MEGAUserAlertTypeContactChangeContactEstablished:
        case MEGAUserAlertTypeContactChangeAccountDeleted:
        case MEGAUserAlertTypeContactChangeBlockedYou:
        case MEGAUserAlertTypeUpdatePendingContactIncomingIgnored:
        case MEGAUserAlertTypeUpdatePendingContactIncomingAccepted:
        case MEGAUserAlertTypeUpdatePendingContactIncomingDenied:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingAccepted:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingDenied:
        case MEGAUserAlertTypeNewShare:
        case MEGAUserAlertTypeDeletedShare:
        case MEGAUserAlertTypeNewShareNodes:
        case MEGAUserAlertTypeRemovedSharesNodes: {
            if (userAlert.email) {
                headingLabel.hidden = NO;
                MOUser *user = [[MEGAStore shareInstance] fetchUserWithEmail:userAlert.email];
                NSString *displayName = user.displayName;
                if (displayName.length > 0) {
                    headingLabel.text = [NSString stringWithFormat:@"%@ (%@)", displayName, user.email];
                } else {
                    headingLabel.text = userAlert.email;
                }
            } else {
                headingLabel.hidden = YES;
                headingLabel.text = nil;
            }
            break;
        }
            
        case MEGAUserAlertTypeScheduledMeetingNew:
        case MEGAUserAlertTypeScheduledMeetingUpdated:
        case MEGAUserAlertTypeScheduledMeetingDeleted: {
            MEGAChatScheduledMeeting *scheduledMeeting = [self scheduledMeetingWithScheduleMeetingId:userAlert.scheduledMeetingId
                                                                                              chatId:userAlert.nodeHandle];
            if(scheduledMeeting) {
                headingLabel.hidden = NO;
                headingLabel.text = scheduledMeeting.title;
            } else {
                headingLabel.hidden = YES;
                headingLabel.text = nil;
            }
            break;
        }
            
        default: {
            headingLabel.hidden = YES;
            headingLabel.text = nil;
            break;
        }
    }
}

- (void)configureContentLabel:(UILabel *)contentLabel forAlert:(MEGAUserAlert *)userAlert indexPath:(NSIndexPath *)indexPath {
    UIFont *boldFont = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleFootnote weight:UIFontWeightBold];
    
    switch (userAlert.type) {
        case MEGAUserAlertTypeIncomingPendingContactRequest:
            contentLabel.text = LocalizedString(@"Sent you a contact request", @"When a contact sent a contact/friend request");
            break;
            
        case MEGAUserAlertTypeIncomingPendingContactCancelled:
            contentLabel.text = LocalizedString(@"Cancelled their contact request", @"A notification that the other user cancelled their contact request so it is no longer valid. E.g. user@email.com cancelled their contact request.");
            break;
            
        case MEGAUserAlertTypeIncomingPendingContactReminder:
            contentLabel.text = LocalizedString(@"Reminder: You have a contact request", @"A reminder notification to remind the user to respond to the contact request.");
            break;
            
        case MEGAUserAlertTypeContactChangeDeletedYou:
            contentLabel.text = LocalizedString(@"Deleted you as a contact", @"A notification telling the user that the other user deleted them as a contact. E.g. user@email.com deleted you as a contact.");
            break;
            
        case MEGAUserAlertTypeContactChangeContactEstablished:
            contentLabel.text = LocalizedString(@"Contact relationship established", @"A notification telling the user that they are now fully connected with the other user (the users are in each other’s address books).");
            break;
            
        case MEGAUserAlertTypeContactChangeAccountDeleted:
            contentLabel.text = LocalizedString(@"Account has been deleted/deactivated", @"A notification telling the user that one of their contact’s accounts has been deleted or deactivated.");
            break;
            
        case MEGAUserAlertTypeContactChangeBlockedYou:
            contentLabel.text = LocalizedString(@"Blocked you as a contact", @"A notification telling the user that another user blocked them as a contact (they will no longer be able to contact them). E.g. name@email.com blocked you as a contact.");
            break;
            
        case MEGAUserAlertTypeUpdatePendingContactIncomingIgnored:
            contentLabel.text = LocalizedString(@"You ignored a contact request", @"Response text after clicking Ignore on an incoming contact request notification.");
            break;
            
        case MEGAUserAlertTypeUpdatePendingContactIncomingAccepted:
            contentLabel.text = LocalizedString(@"You accepted a contact request", @"Response text after clicking Accept on an incoming contact request notification.");
            break;
            
        case MEGAUserAlertTypeUpdatePendingContactIncomingDenied:
            contentLabel.text = LocalizedString(@"You denied a contact request", @"Response text after clicking Deny on an incoming contact request notification.");
            break;
            
        case MEGAUserAlertTypeUpdatePendingContactOutgoingAccepted:
            contentLabel.text = LocalizedString(@"Accepted your contact request", @"When somebody accepted your contact request");
            break;
            
        case MEGAUserAlertTypeUpdatePendingContactOutgoingDenied:
            contentLabel.text = LocalizedString(@"Denied your contact request", @"When somebody denied your contact request");
            break;
            
        case MEGAUserAlertTypeNewShare:
            contentLabel.text = LocalizedString(@"newSharedFolder", @"Notification text body shown when you have received a new shared folder");
            break;
            
        case MEGAUserAlertTypeDeletedShare: {
            MEGANode *node = [MEGASdk.shared nodeForHandle:userAlert.nodeHandle];
            if ([userAlert numberAtIndex:0] == 0) {
                NSAttributedString *nodeName = [[NSAttributedString alloc] initWithString:node.name ?: @""  attributes:@{ NSFontAttributeName : boldFont }];
                NSString *text = LocalizedString(@"inapp.notifications.sharedItems.userLeftTheSharedFolder.message", @"notification text");
                text = [text stringByReplacingOccurrencesOfString:@"[A]" withString:userAlert.email];
                NSRange range = [text rangeOfString:@"[B]"];
                NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
                [attributedText replaceCharactersInRange:range withAttributedString:nodeName];
                contentLabel.attributedText = attributedText;
            } else {
                contentLabel.text = LocalizedString(@"Access to folders was removed.", @"This is shown in the Notification dialog when the email address of a contact is not found and access to the share is lost for some reason (e.g. share removal or contact removal).");
            }
            break;
        }
            
        case MEGAUserAlertTypeNewShareNodes:
            contentLabel.text = [self.viewModel sharedItemNotificationMessageWithFolderCount:[userAlert numberAtIndex:0]
                                                                                   fileCount:[userAlert numberAtIndex:1]];
            break;
            
        case MEGAUserAlertTypeRemovedSharesNodes: {
            int64_t itemCount = [userAlert numberAtIndex:0];
            if (itemCount == 1) {
                contentLabel.text = LocalizedString(@"Removed item from shared folder", @"Notification when on client side when owner of a shared folder removes folder/file from it.");
            } else {
                contentLabel.text = [LocalizedString(@"Removed [X] items from a share", @"Notification popup. Notification for multiple removed items from a share. Please keep [X] as it will be replaced at runtime with the number of removed items.") stringByReplacingOccurrencesOfString:@"[X]" withString:[NSString stringWithFormat:@"%lld", itemCount]];
            }
            break;
        }
            
        case MEGAUserAlertTypePaymentSucceeded: {
            NSString *proPlanString = [userAlert stringAtIndex:0] ? [userAlert stringAtIndex:0] : @"";
            NSAttributedString *proPlan = [[NSAttributedString alloc] initWithString:proPlanString attributes:@{ NSFontAttributeName : boldFont }];
            NSString *text = LocalizedString(@"Your payment for the %1 plan was received.", @"A notification telling the user that their Pro plan payment was successfully received. The %1 indicates the name of the Pro plan they paid for e.g. Lite, PRO III.");
            NSRange range = [text rangeOfString:@"%1"];
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
            [attributedText replaceCharactersInRange:range withAttributedString:proPlan];
            contentLabel.attributedText = attributedText;
            break;
        }
            
        case MEGAUserAlertTypePaymentFailed: {
            NSString *proPlanString = [userAlert stringAtIndex:0] ? [userAlert stringAtIndex:0] : @"";
            NSAttributedString *proPlan = [[NSAttributedString alloc] initWithString:proPlanString attributes:@{ NSFontAttributeName : boldFont }];
            NSString *text = LocalizedString(@"Your payment for the %1 plan was unsuccessful.", @"A notification telling the user that their Pro plan payment was unsuccessful. The %1 indicates the name of the Pro plan they were trying to pay for e.g. Lite, PRO II.");
            NSRange range = [text rangeOfString:@"%1"];
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
            [attributedText replaceCharactersInRange:range withAttributedString:proPlan];
            contentLabel.attributedText = attributedText;
            break;
        }
            
        case MEGAUserAlertTypePaymentReminder: {
            NSInteger days = ([userAlert timestampAtIndex:1] - [NSDate date].timeIntervalSince1970) / secondsInADay;
            NSString *text;
            if (days == 1) {
                text = LocalizedString(@"Your PRO membership plan will expire in 1 day.", @"The professional pricing plan which the user is currently on will expire in one day.");
            } else if (days >= 0) {
                text = [LocalizedString(@"Your PRO membership plan will expire in %1 days.", @"The professional pricing plan which the user is currently on will expire in 5 days. The %1 is a placeholder for the number of days and should not be removed.") stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%td", days]];
            } else if (days == -1) {
                text = LocalizedString(@"Your PRO membership plan expired 1 day ago", @"The professional pricing plan which the user was on expired one day ago.");
            } else {
                text = [LocalizedString(@"Your PRO membership plan expired %1 days ago", @"The professional pricing plan which the user was on expired %1 days ago. The %1 is a placeholder for the number of days and should not be removed.") stringByReplacingOccurrencesOfString:@"%1" withString:[NSString stringWithFormat:@"%td", days]];
            }
            contentLabel.text = text;
            break;
        }
            
        case MEGAUserAlertTypeTakedown:
            contentLabel.attributedText = [self contentForTakedownPubliclySharedNodeWithHandle:userAlert.nodeHandle nodeFont:boldFont];
            break;

        case MEGAUserAlertTypeTakedownReinstated:
            contentLabel.attributedText = [self contentForTakedownReinstatedNodeWithHandle:userAlert.nodeHandle nodeFont:boldFont];
            break;
            
        case MEGAUserAlertTypeScheduledMeetingNew:
            contentLabel.attributedText = [self contentForNewScheduledMeetingWithAlert:userAlert indexPath:indexPath];
            break;
            
        case MEGAUserAlertTypeScheduledMeetingUpdated:
            contentLabel.attributedText = [self contentForUpdatedScheduledMeetingWithAlert:userAlert
                                                                                 indexPath:indexPath
                                                                  checkForOccurrenceChange:YES
                                                                         useDefaultMessage:YES];
            break;
            
        default:
            contentLabel.text = userAlert.title;
            break;
    }
}

- (void)internetConnectionChanged {
    if ([MEGAReachabilityManager isReachable]) {
        [self fetchAlerts];
    } else {
        self.userAlertsArray = @[];
    }
    [self.tableView reloadData];
}

- (void)fetchAlerts {
    NSArray<MEGAUserAlert *> *alerts = MEGASdk.shared.userAlertList.relevantUserAlertsArray;
    
    NSMutableArray *filteredAlerts = [NSMutableArray array];
    for(MEGAUserAlert *alert in alerts) {
        if (alert.type != MEGAUserAlertTypeScheduledMeetingDeleted) {
            [filteredAlerts addObject:alert];
        }
    }
    
    self.userAlertsArray = [filteredAlerts copy];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case NotificationSectionPromos:
            return self.viewModel.promoSectionNumberOfRows;
        case NotificationSectionUserAlerts:
            return self.userAlertsArray.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case NotificationSectionPromos:
            return [self promoCellWithIndexPath:indexPath];
        case NotificationSectionUserAlerts:
            return [self userAlertCellRowAtIndexPath:indexPath];
        default:
            return UITableViewCell.new;
    }
}

- (UITableViewCell *)userAlertCellRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationTableViewCell *cell = (NotificationTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"notificationCell" forIndexPath:indexPath];

    MEGAUserAlert *userAlert = [self.userAlertsArray objectAtIndex:indexPath.row];
    
    [self configureTypeLabel:cell.typeLabel forType:userAlert.type];
    if (userAlert.isSeen) {
        cell.theNewView.hidden = YES;
        cell.backgroundColor = [self notificationCellBackground: userAlert.isSeen];
    } else {
        cell.theNewView.hidden = NO;
        cell.backgroundColor = [self notificationCellBackground: userAlert.isSeen];
    }
    [self configureHeadingLabel:cell.headingLabel forAlert:userAlert];
    [self configureContentLabel:cell.contentLabel forAlert:userAlert indexPath:indexPath];
    cell.dateLabel.textColor = [UIColor mnz_primaryGray];
    cell.dateLabel.text = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[userAlert timestampAtIndex:0]]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == NotificationSectionPromos) {
        [self didTapNotificationAt:indexPath];
        return;
    }
    
    MEGAUserAlert *userAlert = [self.userAlertsArray objectAtIndex:indexPath.row];
    UINavigationController *navigationController = self.navigationController;
    
    switch (userAlert.type) {
        case MEGAUserAlertTypeIncomingPendingContactRequest:
        case MEGAUserAlertTypeIncomingPendingContactReminder: {
            if ([[MEGASdk shared] incomingContactRequests].size) {
                ContactRequestsViewController *contactRequestsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsRequestsViewControllerID"];
                
                [self.navigationController pushViewController:contactRequestsVC animated:YES];
            }
            break;
        }
            
        case MEGAUserAlertTypeIncomingPendingContactCancelled:
        case MEGAUserAlertTypeContactChangeDeletedYou:
        case MEGAUserAlertTypeContactChangeAccountDeleted:
        case MEGAUserAlertTypeContactChangeBlockedYou:
        case MEGAUserAlertTypeUpdatePendingContactIncomingIgnored:
        case MEGAUserAlertTypeUpdatePendingContactIncomingDenied:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingDenied:
            break;
        
        case MEGAUserAlertTypeContactChangeContactEstablished:
        case MEGAUserAlertTypeUpdatePendingContactIncomingAccepted:
        case MEGAUserAlertTypeUpdatePendingContactOutgoingAccepted: {
            MEGAUser *user = [MEGASdk.shared contactForEmail:userAlert.email];
            if (user && user.visibility == MEGAUserVisibilityVisible) {
                [navigationController popToRootViewControllerAnimated:NO];
                ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
                contactsVC.avoidPresentIncomingPendingContactRequests = YES;
                ContactDetailsViewController *contactDetailsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactDetailsViewControllerID"];
                contactDetailsVC.contactDetailsMode = ContactDetailsModeDefault;
                contactDetailsVC.userEmail = user.email;
                contactDetailsVC.userName = user.mnz_fullName;
                contactDetailsVC.userHandle = user.handle;
                [navigationController pushViewController:contactsVC animated:NO];
                [navigationController pushViewController:contactDetailsVC animated:YES];
            }
            break;
        }
            
        case MEGAUserAlertTypeNewShare:
        case MEGAUserAlertTypeDeletedShare:
        case MEGAUserAlertTypeNewShareNodes:
        case MEGAUserAlertTypeRemovedSharesNodes:
        case MEGAUserAlertTypeTakedown:
        case MEGAUserAlertTypeTakedownReinstated: {
            MEGANode *node = [MEGASdk.shared nodeForHandle:userAlert.nodeHandle];
            if (!node.isTakenDown) {
                [node navigateToParentAndPresent];
            }
            break;
        }
            
        case MEGAUserAlertTypePaymentSucceeded:
        case MEGAUserAlertTypePaymentFailed:
        case MEGAUserAlertTypePaymentReminder: {
            [self showUpgradePlanView];
            break;
        }
            
        case MEGAUserAlertTypeScheduledMeetingNew:
        case MEGAUserAlertTypeScheduledMeetingDeleted:
        case MEGAUserAlertTypeScheduledMeetingUpdated:
            [self openChatRoomForUserAlert:userAlert];
            break;
            
        default:
            break;
    }
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

- (NSString *)titleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        text = LocalizedString(@"No notifications",  @"There are no notifications to display.");
    } else {
        text = LocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        image = [UIImage imageNamed:@"notificationsEmptyState"];
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }
    return image;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onUserAlertsUpdate:(MEGASdk *)api userAlertList:(MEGAUserAlertList *)userAlertList {
    [self fetchAlerts];
    [self.tableView reloadData];
}

@end
