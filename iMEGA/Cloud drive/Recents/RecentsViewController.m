
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
#import "NodeTableViewCell.h"
#import "RecentsTableViewHeaderFooterView.h"
#import "ThumbnailViewerTableViewCell.h"

@interface RecentsViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray<MEGARecentActionBucket *> *recentActionBucketArray;

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation RecentsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecentsTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"RecentsHeaderFooterView"];
    
    _recentActionBucketArray = [MEGASdkManager.sharedMEGASdk recentActionsSinceDate:[NSDate dateWithTimeIntervalSince1970:0] maxNodes:10000];
    
    [self.tableView reloadData];
    
    self.tableView.separatorStyle = (self.tableView.numberOfSections == 0) ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    
    self.dateFormatter = NSDateFormatter.alloc.init;
    self.dateFormatter.dateStyle = NSDateFormatterFullStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGARecentActionBucket *recentActionBucket = [self.recentActionBucketArray objectAtIndex:indexPath.section];
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    MEGANode *node = [nodesArray objectAtIndex:0];
    
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
        MEGANode *node = [nodesArray objectAtIndex:0];
        switch (node.type) {
            case MEGANodeTypeFolder: {
                CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                cloudDriveVC.parentNode = node;
                cloudDriveVC.hideSelectorView = YES;
                
                if (self.cloudDrive.displayMode == DisplayModeRubbishBin) {
                    cloudDriveVC.displayMode = self.cloudDrive.displayMode;
                }
                
                [self.navigationController pushViewController:cloudDriveVC animated:YES];
                break;
            }
                
            case MEGANodeTypeFile: {
                if (node.name.mnz_imagePathExtension || node.name.mnz_isVideoPathExtension) {
                    //Show MEGAPhotoBrowser
                } else {
                    [node mnz_openNodeInNavigationController:self.cloudDrive.navigationController folderLink:NO];
                }
                break;
            }
                
            default:
                break;
        }
    } else {
        //Show MEGAPhotoBrowser / BrowserViewController 
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text = (MEGAReachabilityManager.isReachable) ? AMLocalizedString(@"No recent activity", @"Message shown when the user has not recent activity in their account.") : AMLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
    
    return [NSAttributedString.alloc initWithString:text attributes:Helper.titleAttributesForEmptyState];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image = (MEGAReachabilityManager.isReachable) ? [UIImage imageNamed:@"recentsEmptyState"] : [UIImage imageNamed:@"noInternetEmptyState"];
    
    return image;
}

@end
