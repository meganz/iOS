#import "RecentsViewController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "EmptyStateView.h"
#import "MEGAPhotoBrowserViewController.h"
#import "NodeTableViewCell.h"
#import "RecentsTableViewHeaderFooterView.h"
#import "ThumbnailViewerTableViewCell.h"
#import "MEGARecentActionBucket+MNZCategory.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"

@import ChatRepo;
@import MEGAFoundation;
#import "LocalizationHelper.h"
@import MEGAAppSDKRepo;

@interface RecentsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TextFileEditable, RecentsPreferenceProtocol>

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation RecentsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureTokenColors];
    
    self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    self.tableView.bounces = false;
    
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    self.tableView.estimatedSectionHeaderHeight = 36.0f;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecentsTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"RecentsHeaderFooterView"];
    
    [self getRecentActions];
    
    self.tableView.separatorStyle = (self.tableView.numberOfSections == 0) ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    
    self.dateFormatter = NSDateFormatter.alloc.init;
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    
    RecentsPreferenceManager.delegate = self;
    
    self.tableView.sectionHeaderTopPadding = 0.0f;
    
    [self onViewDidLoad];
}

- (void)removeFromParentViewController {
    [super removeFromParentViewController];
    
    RecentsPreferenceManager.delegate = nil;
}

- (RecentsViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [self makeRecentsViewModel];
    }
    return _viewModel;
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:indexPath.section];
    if (!recentActionBucket) {
        return;
    }
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    MEGANode *node = nodesArray.firstObject;
    
    if (node) {
        BOOL isNodeUndecrypted = [node isUndecryptedWithOwnerEmail:recentActionBucket.userEmail
                                                                in:MEGASdk.shared];
        if (isNodeUndecrypted) {
            [self showContactVerificationViewForUserEmail:recentActionBucket.userEmail];
        } else {
            [self.delegate showCustomActionsForNode:node fromSender:sender];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return RecentsPreferenceManager.showRecents ? self.recentActionBucketArray.count : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return RecentsPreferenceManager.showRecents ? (self.recentActionBucketArray.count > 0 ? 1 : 0) : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:indexPath.section];
    if (!recentActionBucket) {
        return UITableViewCell.new;
    }
    
    if (recentActionBucket.nodesList.size > 1 && recentActionBucket.isMedia) {
        return [self thumbnailViewerTableViewCellForIndexPath:indexPath recentActionBucket:recentActionBucket];
    } else {
        return [self nodeTableViewCellForIndexPath:indexPath recentActionBucket:recentActionBucket];
    }
}

- (NodeTableViewCell *)nodeTableViewCellForIndexPath:(NSIndexPath *)indexPath recentActionBucket:(MEGARecentActionBucket *)recentActionBucket {
    NSString *cellReuseIdentifier =  [recentActionBucket.userEmail isEqualToString:MEGASdk.currentUserEmail] ? @"RecentsNodeTVC" : @"RecentsSharedNodeTVC";
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [NodeTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    [cell configureForRecentAction:recentActionBucket];
    
    return cell;
}

- (ThumbnailViewerTableViewCell *)thumbnailViewerTableViewCellForIndexPath:(NSIndexPath *)indexPath recentActionBucket:(MEGARecentActionBucket *)recentActionBucket {
    NSString *cellReuseIdentifier =  [recentActionBucket.userEmail isEqualToString:MEGASdk.currentUserEmail] ? @"RecentsMediaTVC" : @"RecentsSharedMediaTVC";
    ThumbnailViewerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [ThumbnailViewerTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    [cell configureForRecentAction:recentActionBucket];
    __weak typeof(self) weakSelf = self;
    cell.showNodeAction = ^(UIViewController *viewController) {
        [weakSelf.delegate showSelectedNodeInViewController:viewController];
    };
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *reuseIdentifier = @"RecentsHeaderFooterView";
    RecentsTableViewHeaderFooterView *recentsTVHFV = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:section];
    if (!recentActionBucket) {
        return nil;
    }
    if (section > 0) {
        MEGARecentActionBucket *previousRecentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:(section - 1)];
        if (!previousRecentActionBucket) {
            return nil;
        }
        if ([previousRecentActionBucket.timestamp isSameDayAsDate:recentActionBucket.timestamp]) {
            recentsTVHFV.dateLabel.text = @"";
            return recentsTVHFV;
        }
    }
    
    if (recentActionBucket.timestamp.isToday) {
        recentsTVHFV.dateLabel.text = LocalizedString(@"Today", @"");
    } else if (recentActionBucket.timestamp.isYesterday) {
        recentsTVHFV.dateLabel.text = LocalizedString(@"Yesterday", @"");
    } else {
        NSString *dateString = [self.dateFormatter stringFromDate:recentActionBucket.timestamp];
        recentsTVHFV.dateLabel.text = dateString;
    }
    
    return recentsTVHFV;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:section];
    if (!recentActionBucket) {
        return 0;
    }
    if (section > 0) {
        MEGARecentActionBucket *previousRecentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:(section - 1)];
        if (!previousRecentActionBucket) {
            return 0;
        }
        if ([previousRecentActionBucket.timestamp isSameDayAsDate:recentActionBucket.timestamp]) {
            return 0;
        }
    }
    
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectOrNilAtIndex:indexPath.section];
    if (!recentActionBucket) {
        return;
    }
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    
    MEGANode *node = nodesArray.firstObject;
    if (node) {
        BOOL isNodeUndecrypted = [node isUndecryptedWithOwnerEmail:recentActionBucket.userEmail
                                                                in:MEGASdk.shared];
        
        if (isNodeUndecrypted) {
            [self showContactVerificationViewForUserEmail:recentActionBucket.userEmail];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            return;
        }
    }
    
    if (nodesArray.count == 1) {
        if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
            [self.delegate showSelectedNodeInViewController: [self photosBrowserViewControllerWith:nodesArray]];
        } else {
            if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:node.name] && ![FileExtensionGroupOCWrapper verifyIsVideo:node.name] && node.mnz_isPlayable) {
                if ([AudioPlayerManager.shared isPlayerDefined] && [AudioPlayerManager.shared isPlayerAlive]) {
                    [AudioPlayerManager.shared initMiniPlayerWithNode:node fileLink:nil filePaths:nil isFolderLink:NO presenter:self shouldReloadPlayerInfo:YES shouldResetPlayer:YES isFromSharedItem: NO];
                } else {
                    [self initFullScreenPlayerWithNode:node fileLink:nil filePaths:nil isFolderLink:NO presenter:self];
                }
            } else {
                UIViewController *displayViewController = [self viewControllerForNode:node withFolderLink:NO];
                [self.delegate showSelectedNodeInViewController:displayViewController];
            }
        }
    } else {
        if (recentActionBucket.isMedia) {
            recentActionBucket.mnz_isExpanded = !recentActionBucket.mnz_isExpanded;
            [UIView performWithoutAnimation:^{
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }];
        } else {
            [self showRecentActionWithBucket:recentActionBucket];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIViewController *)viewControllerForNode:(MEGANode *)node withFolderLink:(BOOL)isFolderLink {
    if ([FileExtensionGroupOCWrapper verifyIsMultiMedia:node.name] && MEGAChatSdk.shared.mnz_existsActiveCall) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LocalizedString(@"It is not possible to play content while there is a call in progress", @"Message shown when there is an ongoing call and the user tries to play an audio or video") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
        return alertController;
    } else {
        return [node mnz_viewControllerForNodeInFolderLink:isFolderLink fileLink:nil isFromSharedItem:NO inViewController: self];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initForHomeWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.descriptionButton addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    [emptyStateView.descriptionButton setTitle:LocalizedString(@"recents.emptyState.activityHidden.button", @"Title of the button show in Recents on the empty state when the recent activity is hidden") forState:UIControlStateNormal];
    emptyStateView.descriptionButton.hidden = RecentsPreferenceManager.showRecents;
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if (RecentsPreferenceManager.showRecents) {
        text = (MEGAReachabilityManager.isReachable) ? LocalizedString(@"No recent activity", @"Message shown when the user has not recent activity in their account.") : LocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    } else {
        text = LocalizedString(@"recents.emptyState.activityHidden.title", @"Title show in Recents on the empty state when the recent activity is hidden");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (RecentsPreferenceManager.showRecents) {
        if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
        }
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image;
    if (RecentsPreferenceManager.showRecents) {
        image = (MEGAReachabilityManager.isReachable) ? [UIImage megaImageWithNamed:@"recentsEmptyState"] : [UIImage megaImageWithNamed:@"noInternetEmptyState"];
    } else {
        image = [UIImage megaImageWithNamed:@"recentsEmptyState"];
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
    if (RecentsPreferenceManager.showRecents) {
        if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    } else {
        [RecentsPreferenceManager setShowRecents:YES];
        [self.tableView reloadEmptyDataSet];
        [self.tableView reloadData];
    }
}

#pragma mark - RecentsPreferenceProtocol

- (void)recentsPreferenceChanged {
    [self.tableView reloadData];
}

@end
