#import "OfflineTableViewViewController.h"

#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "Helper.h"
#import "MEGAStore.h"

#import "OfflineTableViewCell.h"
#import "OfflineViewController.h"
#import "MEGA-Swift.h"

static NSString *kFileName = @"kFileName";
static NSString *kPath = @"kPath";

@interface OfflineTableViewViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation OfflineTableViewViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //White background for the view behind the table view
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Public

- (void)tableViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    [self.offline setViewEditing:editing];
    
    if (editing) {
        for (OfflineTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        for (OfflineTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectedBackgroundView = nil;
        }
    }
}

#pragma mark - IBAction

- (IBAction)moreButtonTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    OfflineTableViewCell *cell = (OfflineTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *itemPath = [self.offline.currentOfflinePath stringByAppendingPathComponent:cell.nameLabel.text];
    
    [self.offline showInfoFilePath:itemPath at:indexPath from:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = self.offline.searchController.isActive ? self.offline.searchItemsArray.count : self.offline.offlineSortedItems.count;
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OfflineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"offlineTableViewCell" forIndexPath:indexPath];
    
    NSString *directoryPathString = [self.offline currentOfflinePath];
    NSString *nameString = [[self.offline itemAtIndexPath:indexPath] objectForKey:kFileName];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
    
    cell.itemNameString = nameString;
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    NSString *handleString = offNode.base64Handle;
    
    cell.thumbnailPlayImageView.hidden = YES;
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    // Note: nameString might be `nil` due to concurrency loading (becayse self.offline could be empty/nil), therefore we need to check nameString to fully determine
    // whether the item is a directory or not.
    if (isDirectory && nameString) {
        cell.thumbnailImageView.image = UIImage.mnz_folderImage;
        
        NSInteger files = 0;
        NSInteger folders = 0;
        
        NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathForItem error:nil];
        for (NSString *file in directoryContents) {
            BOOL isDirectory;
            NSString *path = [pathForItem stringByAppendingPathComponent:file];
            if (![path.pathExtension.lowercaseString isEqualToString:@"mega"]) {
                [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
                isDirectory ? folders++ : files++;
            }
        }
        
        cell.infoLabel.text = [NSString mnz_stringByFiles:files andFolders:folders];
    } else {
        NSString *extension = nameString.pathExtension.lowercaseString;
        
        NSString *thumbnailFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
        thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
        
        if (handleString) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                [self refreshThumbnailImageFor:cell thumbnailFilePath:thumbnailFilePath nodeName:nameString];
            } else {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    if ([MEGASdk.shared createThumbnail:pathForItem destinatioPath:thumbnailFilePath]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self refreshThumbnailImageFor:cell thumbnailFilePath:thumbnailFilePath nodeName:nameString];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [cell.thumbnailImageView setImage:[NodeAssetsManager.shared imageFor:extension]];
                        });
                    }
                });
            }
        } else {
            [cell.thumbnailImageView setImage:[NodeAssetsManager.shared imageFor:extension]];
            NSURL *url = [NSURL fileURLWithPath:pathForItem];
            [cell setThumbnailWithUrl:url];
        }
        
        NSDate *modificationDate = [NSFileManager.defaultManager attributesOfItemAtPath:pathForItem error:nil][NSFileModificationDate];
        
        unsigned long long size = [NSFileManager.defaultManager attributesOfItemAtPath:pathForItem error:nil].fileSize;
        
        cell.infoLabel.text = [NSString stringWithFormat:@"%@ • %@", [NSString memoryStyleStringFromByteCount:size], modificationDate.mnz_formattedDateMediumTimeShortStyle];
    }
    cell.nameLabel.text = [MEGASdk.shared unescapeFsIncompatible:nameString destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    
    if (self.tableView.isEditing) {
        for (NSURL *url in self.offline.selectedItems) {
            if ([url.path isEqualToString:pathForItem]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView.isEditing) {
        NSURL *filePathURL = [[self.offline itemAtIndexPath:indexPath] objectForKey:kPath];
        
        for (NSURL *tempURL in self.offline.selectedItems) {
            if (tempURL == filePathURL) {
                return;
            }
        }
        
        [self.offline.selectedItems addObject:filePathURL];
        
        [self.offline updateNavigationBarTitle];
        [self.offline enableButtonsBySelectedItems];
        
        self.offline.allItemsSelected = (self.offline.selectedItems.count == self.offline.offlineSortedItems.count);
        
        return;
    }
    
    OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self.offline itemTapped:cell.nameLabel.text atIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView.isEditing) {
        NSURL *filePathURL = [[self.offline itemAtIndexPath:indexPath] objectForKey:kPath];
        
        NSMutableArray *tempArray = self.offline.selectedItems.copy;
        for (NSURL *url in tempArray) {
            if ([url.filePathURL isEqual:filePathURL]) {
                [self.offline.selectedItems removeObject:url];
            }
        }
        
        [self.offline updateNavigationBarTitle];
        [self.offline enableButtonsBySelectedItems];
        
        self.offline.allItemsSelected = NO;
        
        return;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return self.offline.flavor == AccountScreen;
}

- (void)tableView:(UITableView *)tableView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setTableViewEditing:YES animated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        NSString *itemPath = [[self.offline currentOfflinePath] stringByAppendingPathComponent:cell.itemNameString];
        [self.offline showRemoveAlertWithConfirmAction:^{
            [self.offline removeOfflineItems:@[[NSURL fileURLWithPath:itemPath]]];
            [self.offline updateNavigationBarTitle];
        } andCancelAction:^{
            [self.offline setEditMode:NO];
        }];
    }];
    
    deleteAction = [self configureDeleteContextMenu: deleteAction];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point {
    if (self.offline.flavor == AccountScreen) {
        NSString *nameString = [[self.offline itemAtIndexPath:indexPath] objectForKey:kFileName];
        NSString *pathForItem = [self.offline.currentOfflinePath stringByAppendingPathComponent:nameString];
        return [self tableView:tableView contextMenuConfigurationForRowAt:indexPath itemPath:pathForItem];
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView
willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration
         animator:(id<UIContextMenuInteractionCommitAnimating>)animator {
    [self willPerformPreviewActionForMenuWithAnimator:animator];
}

@end
