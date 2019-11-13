
#import "RecentsViewController.h"

#import "NSDate+DateTools.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"

#import "CloudDriveViewController.h"
#import "EmptyStateView.h"
#import "MEGAPhotoBrowserViewController.h"
#import "NodeTableViewCell.h"
#import "RecentsTableViewHeaderFooterView.h"
#import "ThumbnailViewerTableViewCell.h"

@interface RecentsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate>

@property (strong, nonatomic) NSArray<MEGARecentActionBucket *> *recentActionBucketArray;

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation RecentsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecentsTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"RecentsHeaderFooterView"];
    
    self.recentActionBucketArray = MEGASdkManager.sharedMEGASdk.recentActions;
    
    [self.tableView reloadData];
    
    self.tableView.separatorStyle = (self.tableView.numberOfSections == 0) ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    
    self.dateFormatter = NSDateFormatter.alloc.init;
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    
    [MEGASdkManager.sharedMEGASdk addMEGADelegate:self];
}

- (void)removeFromParentViewController {
    [super removeFromParentViewController];
    
    [MEGASdkManager.sharedMEGASdk removeMEGADelegate:self];
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:indexPath.section];
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    MEGANode *node = nodesArray.firstObject;
    
    [self.cloudDrive showCustomActionsForNode:node sender:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (MEGAReachabilityManager.isReachable) {
        numberOfSections = self.recentActionBucketArray.count;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (MEGAReachabilityManager.isReachable) {
        numberOfRows = 1;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:indexPath.section];
    if (recentActionBucket.nodesList.size.integerValue > 1) {
        if (recentActionBucket.isMedia) {
            return [self thumbnailViewerTableViewCellForIndexPath:indexPath recentActionBucket:recentActionBucket];
        } else {
            return [self nodeTableViewCellForIndexPath:indexPath recentActionBucket:recentActionBucket];
        }
    } else {
        return [self nodeTableViewCellForIndexPath:indexPath recentActionBucket:recentActionBucket];
    }
    
    return UITableViewCell.new;
}

- (NodeTableViewCell *)nodeTableViewCellForIndexPath:(NSIndexPath *)indexPath recentActionBucket:(MEGARecentActionBucket *)recentActionBucket {
    NSString *cellReuseIdentifier =  [recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail] ? @"RecentsNodeTVC" : @"RecentsSharedNodeTVC";
    NodeTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [NodeTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    [cell configureForRecentAction:recentActionBucket];
    
    return cell;
}

- (ThumbnailViewerTableViewCell *)thumbnailViewerTableViewCellForIndexPath:(NSIndexPath *)indexPath recentActionBucket:(MEGARecentActionBucket *)recentActionBucket {
    NSString *cellReuseIdentifier =  [recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail] ? @"RecentsMediaTVC" : @"RecentsSharedMediaTVC";
    ThumbnailViewerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [ThumbnailViewerTableViewCell.alloc initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    [cell configureForRecentAction:recentActionBucket];
    
    cell.cloudDrive = self.cloudDrive;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString *reuseIdentifier = @"RecentsHeaderFooterView";
    RecentsTableViewHeaderFooterView *recentsTVHFV = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseIdentifier];
    
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:section];
    if (section > 0) {
        MEGARecentActionBucket *previousRecentActionBucket = [self.recentActionBucketArray objectAtIndex:(section - 1)];
        if ([previousRecentActionBucket.timestamp isSameDay:recentActionBucket.timestamp]) {
            recentsTVHFV.dateLabel.text = @"";
            return recentsTVHFV;
        }
    }
    
    if (recentActionBucket.timestamp.isToday) {
        recentsTVHFV.dateLabel.text = AMLocalizedString(@"Today", @"").uppercaseString;
    } else if (recentActionBucket.timestamp.isYesterday) {
        recentsTVHFV.dateLabel.text = AMLocalizedString(@"Yesterday", @"").uppercaseString;
    } else {
        NSString *dateString = [self.dateFormatter stringFromDate:recentActionBucket.timestamp];
        recentsTVHFV.dateLabel.text = dateString.uppercaseString;
    }
    
    return recentsTVHFV;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:section];
    if (section > 0) {
        MEGARecentActionBucket *previousRecentActionBucket = [self.recentActionBucketArray objectAtIndex:(section - 1)];
        if ([previousRecentActionBucket.timestamp isSameDay:recentActionBucket.timestamp]) {
            return 0;
        }
    }
    
    return 36.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow = 0;
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:indexPath.section];
    if (recentActionBucket.nodesList.size.integerValue > 1) {
        if (recentActionBucket.isMedia) {
            heightForRow = [recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail] ? 178.0f : 198.0f;
        } else {
            heightForRow = [recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail] ? 60.0f : 80.f;
        }
    } else {
        heightForRow = [recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail] ? 60.0f : 80.f;
    }

    return heightForRow;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:indexPath.section];
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    if (nodesArray.count == 1) {
        MEGANode *node = nodesArray.firstObject;
        if (node.name.mnz_imagePathExtension || node.name.mnz_isVideoPathExtension) {
            MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:nodesArray.mutableCopy api:MEGASdkManager.sharedMEGASdk displayMode:DisplayModeCloudDrive presentingNode:nodesArray.firstObject preferredIndex:0];
            
            [self.cloudDrive.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
        } else {
            [node mnz_openNodeInNavigationController:self.cloudDrive.navigationController folderLink:NO];
        }
    } else {
        if (recentActionBucket.isMedia) {
            NSMutableArray<MEGANode *> *mediaNodesArray = [recentActionBucket.nodesList mnz_mediaNodesMutableArrayFromNodeList];
            MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:MEGASdkManager.sharedMEGASdk displayMode:DisplayModeCloudDrive presentingNode:nodesArray.firstObject preferredIndex:0];
            
            [self.cloudDrive.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
        } else {
            CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.nodes = recentActionBucket.nodesList;
            cloudDriveVC.recentActionBucket = recentActionBucket;
            cloudDriveVC.displayMode = DisplayModeRecents;
            
            [self.cloudDrive.navigationController pushViewController:cloudDriveVC animated:YES];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text = (MEGAReachabilityManager.isReachable) ? AMLocalizedString(@"No recent activity", @"Message shown when the user has not recent activity in their account.") : AMLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image = (MEGAReachabilityManager.isReachable) ? [UIImage imageNamed:@"recentsEmptyState"] : [UIImage imageNamed:@"noInternetEmptyState"];
    
    return image;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    BOOL shouldProcessOnNodesUpdate = NO;
    NSArray *nodesUpdateArray = nodeList.mnz_nodesArrayFromNodeList;
    for (MEGANode *nodeUpdated in nodesUpdateArray) {
        if ((nodeUpdated.isFolder && [nodeUpdated hasChangedType:MEGANodeChangeTypeNew]) || [nodeUpdated hasChangedType:MEGANodeChangeTypeRemoved]) {
            shouldProcessOnNodesUpdate = NO;
        } else {
            shouldProcessOnNodesUpdate = YES;
            break;
        }
    }
    
    if (shouldProcessOnNodesUpdate) {
        self.recentActionBucketArray = MEGASdkManager.sharedMEGASdk.recentActions;
        [self.tableView reloadData];
    }
}

@end
