/**
 * @file PhotosViewController.m
 * @brief View controller that show your photos upload to Camera Uploads folder
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "PhotosViewController.h"
#import "PhotoCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "Helper.h"
#import "MEGAPreview.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "AppDelegate.h"
#import "BrowserViewController.h"

#import "NSString+MNZCategory.h"
#import "MEGAProxyServer.h"

@interface PhotosViewController () <UIAlertViewDelegate, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate> {
    dispatch_queue_t createAttributesQueue;
    dispatch_group_t createAttributesGroup;
    dispatch_semaphore_t createAttributesSemaphore;
    
    BOOL allNodesSelected;
    NSMutableArray *exportLinks;
    NSUInteger remainingOperations;
    NSUInteger itemsPerRow;
}

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;
@property (nonatomic, strong) NSMutableArray *previewsArray;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) ALAssetsLibrary *library;

@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *transferredBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalBytesLabel;

@property (weak, nonatomic) IBOutlet UIButton *enableCameraUploadsButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadProgressViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photosCollectionViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photosCollectionViewBottonLayoutConstraint;

@property (nonatomic, strong) NSMutableDictionary *selectedItemsDictionary;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

@end

@implementation PhotosViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.photosCollectionView.emptyDataSetSource = self;
    self.photosCollectionView.emptyDataSetDelegate = self;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [self.dateFormatter setLocale:locale];

    self.library = [[ALAssetsLibrary alloc] init];
    
    createAttributesQueue = dispatch_queue_create("Create thumbnails and previews", NULL);
    createAttributesGroup = dispatch_group_create();
    
    createAttributesSemaphore = dispatch_semaphore_create(8);
    
    self.selectedItemsDictionary = [[NSMutableDictionary alloc] init];
    
    [self.navigationItem setRightBarButtonItem:self.editButtonItem];
    [self.editButtonItem setImage:[UIImage imageNamed:@"edit"]];
    
    if (iPad) {
        itemsPerRow = 7;
    } else {
        if (iPhone4X || iPhone5X) {
            itemsPerRow = 3;
        } else {
            itemsPerRow = 4;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self setEditing:NO animated:NO];
    
    [self.enableCameraUploadsButton setTitle:AMLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads") forState:UIControlStateNormal];
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    self.photosCollectionView.emptyDataSetSource = nil;
    self.photosCollectionView.emptyDataSetDelegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private methods

- (void)reloadUI {
    NSMutableDictionary *photosByMonthYearDictionary = [NSMutableDictionary new];
    
    self.photosByMonthYearArray = [NSMutableArray new];
    NSMutableArray *photosArray = [NSMutableArray new];
    
    self.parentNode = [[MEGASdkManager sharedMEGASdk] childNodeForParent:[[MEGASdkManager sharedMEGASdk] rootNode] name:@"Camera Uploads"];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode order:MEGASortOrderTypeModificationDesc];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMMM yyyy"];
    
    for (NSInteger i = 0; i < [self.nodeList.size integerValue]; i++) {
        MEGANode *node = [self.nodeList nodeAtIndex:i];
        
        if (!isImage([node name].lowercaseString.pathExtension) && !isVideo([node name].lowercaseString.pathExtension)) {
            continue;
        }
        
        NSString *currentMonthYearString = [df stringFromDate:[node modificationTime]];
        
        if (![photosByMonthYearDictionary objectForKey:currentMonthYearString]) {
            photosByMonthYearDictionary = [NSMutableDictionary new];
            photosArray = [NSMutableArray new];
            [photosArray addObject:node];
            [photosByMonthYearDictionary setObject:photosArray forKey:currentMonthYearString];
            [self.photosByMonthYearArray addObject:photosByMonthYearDictionary];
            
        } else {
            [photosArray addObject:node];
        }
    }
    
    [self.photosCollectionView reloadData];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] transfers];
        NSInteger transferListSize = [[transferList size] integerValue];
        
        for (NSInteger i = 0; i < transferListSize; i++) {
            
            MEGATransfer *transfer = [transferList transferAtIndex:i];
            
            if (([transfer type] == MEGATransferTypeUpload) && (self.uploadProgressViewTopLayoutConstraint != 0)) {
                [self showProgressView];
            }
        }
        
        [self.enableCameraUploadsButton setHidden:YES];
        [self.enableCameraUploadsButton setFrame:CGRectMake(0, 0, 0, 0)];
        
        self.photosCollectionViewBottonLayoutConstraint.constant = -49;
    } else {
        [self.enableCameraUploadsButton setHidden:NO];
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
        self.photosCollectionViewBottonLayoutConstraint.constant = 0;
    }
    
    if ([self.photosCollectionView allowsMultipleSelection]) {
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
    } else {
        
        [self.navigationItem setTitle:@"Camera Uploads"];
    }
}

- (void)showProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = 0;
        self.photosCollectionViewTopLayoutConstraint.constant = 60;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)hideProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)internetConnectionChanged {
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.editButtonItem setEnabled:boolValue];
}

#pragma mark - IBAction

- (IBAction)enableCameraUploadsTouchUpInside:(UIButton *)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    CameraUploadsTableViewController *cameraUploadsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"cameraUploadsSettingsID"];
    
    [self.navigationController pushViewController:cameraUploadsTableViewController animated:YES];
    
    if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized && [ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusNotDetermined) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", @"Cancelar") : AMLocalizedString(@"ok", @"OK")) otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", @"OK") : nil), nil];
        [alert show];
    } else {
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
        [[CameraUploads syncManager] getAllAssetsForUpload];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
        [self reloadUI];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedItemsDictionary removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        NSInteger nodeListSize = [[self.nodeList size] integerValue];
        
        for (NSInteger i = 0; i < nodeListSize; i++) {
            n = [self.nodeList nodeAtIndex:i];
            [self.selectedItemsDictionary setObject:n forKey:[NSNumber numberWithLongLong:n.handle]];
        }
        
        allNodesSelected = YES;
        [self.navigationItem setTitle:[NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"%lu Items selected"), (long)[[self.nodeList size] unsignedIntegerValue]]];
    } else {
        allNodesSelected = NO;
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select title")];
    }
    
    if (self.selectedItemsDictionary.count == 0) {
        [self.downloadBarButtonItem setEnabled:NO];
        [self.shareBarButtonItem setEnabled:NO];
        [self.moveBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
        
    } else {
        [self.downloadBarButtonItem setEnabled:YES];
        [self.shareBarButtonItem setEnabled:YES];
        [self.moveBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
    }
    
    [self.photosCollectionView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.editButtonItem setTitle:@""];
    
    if (editing) {
        [self.editButtonItem setImage:[UIImage imageNamed:@"done"]];
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
        [self.photosCollectionView setAllowsMultipleSelection:YES];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
    } else {
        [self.editButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        [self.navigationItem setTitle:@"Camera Uploads"];
        [self.photosCollectionView setAllowsMultipleSelection:NO];
        [self.selectedItemsDictionary removeAllObjects];
        [self.photosCollectionView reloadData];
        self.navigationItem.leftBarButtonItems = @[];
    }
    if (![self.selectedItemsDictionary count]) {
        [self.downloadBarButtonItem setEnabled:NO];
        [self.shareBarButtonItem setEnabled:NO];
        [self.moveBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    }
    
    [self.tabBarController.tabBar addSubview:self.toolbar];
    
    [UIView animateWithDuration:animated ? .33 : 0 animations:^{
        self.toolbar.frame = CGRectMake(0, editing ? 0 : 49 , CGRectGetWidth(self.view.frame), 49);
    }];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    for (MEGANode *n in [self.selectedItemsDictionary allValues]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:n]) {
            return;
        }
    }
    
    for (MEGANode *n in [self.selectedItemsDictionary allValues]) {
        if ([n type] == MEGANodeTypeFile) {
            [Helper downloadNode:n folder:@"" folderLink:NO];
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", @"Download started")];
            
        } else if ([n type] == MEGANodeTypeFolder) {
            NSString *folderName = [[[n base64Handle] stringByAppendingString:@"_"] stringByAppendingString:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[n name]]];
            NSString *folderPath = [[Helper pathForOffline] stringByAppendingPathComponent:folderName];
            
            if ([Helper createOfflineFolder:folderName folderPath:folderPath]) {
                [Helper downloadNodesOnFolder:folderPath parentNode:n folderLink:NO];
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", @"Download started")];
            }
        }
    }
    [self setEditing:NO animated:YES];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    exportLinks = [NSMutableArray new];
    remainingOperations = self.selectedItemsDictionary.count;
    
    for (MEGANode *n in [self.selectedItemsDictionary allValues]) {
        [[MEGASdkManager sharedMEGASdk] exportNode:n delegate:self];
    }
}

- (IBAction)moveCopyAction:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *mcnc = [storyboard instantiateViewControllerWithIdentifier:@"moveNodeNav"];
    [self presentViewController:mcnc animated:YES completion:nil];
    
    BrowserViewController *mcnvc = mcnc.viewControllers.firstObject;
    mcnvc.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    mcnvc.selectedNodesArray = [NSArray arrayWithArray:[self.selectedItemsDictionary allValues]];
    [mcnvc setBrowseAction:BrowseActionCopyAndMove];
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    NSString *message = (self.selectedItemsDictionary.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"moveMultipleNodesToRubbishBinMessage", nil), self.selectedItemsDictionary.count] : [NSString stringWithString:AMLocalizedString(@"moveNodeToRubbishBinMessage", nil)];
    
    UIAlertView *removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveNodeToRubbishBinTitle", @"Remove node from rubbish bin") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"Cancel") otherButtonTitles:AMLocalizedString(@"ok", @"OK"), nil];
    removeAlertView.tag = 1;
    [removeAlertView show];
}

#pragma mark - UICollectioViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.photosByMonthYearArray count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    return [array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"photoCellId";
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    MEGANode *node = nil;
    
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    node = [array objectAtIndex:indexPath.row];
    
    // check if the thumbnail exist in the cache directory
    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
    
    // check if the photo exist in photo library
    if (!fileExists) {
        NSString *dateString = [node.name stringByDeletingPathExtension];
        
        if (!([dateString rangeOfString:@"_"].location == NSNotFound) && [node hasThumbnail]) {
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:self];
        } else {
            NSDate *dateFromString = [self.dateFormatter dateFromString:dateString];
            NSString *dateKey = [NSString stringWithFormat:@"%lld", (long long)[dateFromString timeIntervalSince1970]];
            
            NSURL *photoUrl = [[(AppDelegate *)[[UIApplication sharedApplication] delegate] photosUrlDictionary] objectForKey:dateKey];
            
            if (!photoUrl) {
                if ([node hasThumbnail]) {
                    [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:self];
                }
            } else {
                [self.library assetForURL:photoUrl
                              resultBlock:^(ALAsset *asset) {
                                  
                                  dispatch_group_async(createAttributesGroup, createAttributesQueue, ^{
                                      dispatch_semaphore_wait(createAttributesSemaphore, DISPATCH_TIME_FOREVER);
                                      
                                      NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
                                      NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
                                      NSString *name = [[self.dateFormatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
                                      NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
                                      
                                      ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
                                      
                                      if (!assetRepresentation) {
                                          return;
                                      }
                                      
                                      Byte *buffer = (Byte *)malloc(assetRepresentation.size);
                                      NSUInteger buffered = [assetRepresentation getBytes:buffer fromOffset:0 length:assetRepresentation.size error:nil];
                                      
                                      NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                                      [data writeToFile:localFilePath atomically:YES];
                                      
                                      NSError *error = nil;
                                      NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
                                      
                                      [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
                                      if (error) {
                                          [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
                                      }
                                      
                                      NSString *localCRC = [[MEGASdkManager sharedMEGASdk] CRCForFilePath:localFilePath];
                                      NSString *nodeCRC = [[MEGASdkManager sharedMEGASdk] CRCForNode:node];
                                      
                                      if ([localCRC isEqualToString:nodeCRC]) {
                                          [[MEGASdkManager sharedMEGASdk] createThumbnail:localFilePath destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"]];
                                          [[MEGASdkManager sharedMEGASdk] createPreview:localFilePath destinatioPath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previews"]];
                                          
                                          dispatch_async(dispatch_get_main_queue(), ^(){
                                              [self.photosCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]]];
                                          });
                                          
                                          BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
                                          if (!success || error) {
                                              [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
                                          }
                                          
                                          if (![node hasThumbnail]) {
                                              [[MEGASdkManager sharedMEGASdk] setThumbnailNode:node sourceFilePath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"] delegate:self];
                                          }
                                          
                                          if (![node hasPreview]) {
                                              [[MEGASdkManager sharedMEGASdk] setPreviewNode:node sourceFilePath:[Helper pathForNode:node searchPath:NSCachesDirectory directory:@"previews"] delegate:self];
                                          }
                                      } else {
                                          [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
                                      }
                                      
                                      dispatch_semaphore_signal(createAttributesSemaphore);
                                  });
                                  
                              }
                 
                             failureBlock:^(NSError *error) {
                                 [MEGASdk logWithLevel:MEGALogLevelError message:@"assetForURL failureBlock"];
                             }];
            }
        }
    }
    
    if (!fileExists) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    } else {
        [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
    }
    
    cell.nodeHandle = [node handle];
    
    if ([self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]]) {
        cell.thumbnailImageView.layer.borderColor = [megaRed CGColor];
        cell.thumbnailImageView.layer.borderWidth = 3.0;
        [cell.thumbnailImageView.layer setOpacity:0.6];
    } else {
        cell.thumbnailImageView.layer.borderColor = nil;
        cell.thumbnailImageView.layer.borderWidth = 0.0;
        [cell.thumbnailImageView.layer setOpacity:1.0];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        static NSString *headerIdentifier = @"photoHeaderId";
        
        HeaderCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        
        if (!header) {
            header = [[HeaderCollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 40)];
        }
        
        
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
        NSString *month = [[dict allKeys] objectAtIndex:0];
        
        NSString *photosPerMonth = nil;
        NSInteger numberPhotosPerMonth = [[dict objectForKey:month] count];
        if ( numberPhotosPerMonth > 1) {
            photosPerMonth = [NSString stringWithFormat:AMLocalizedString(@"photosPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        } else {
            photosPerMonth = [NSString stringWithFormat:AMLocalizedString(@"photoPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        }
        
        NSString *sectionText = [NSString stringWithFormat:@"%@ (%@)", month, photosPerMonth];
        
        [header.dateLabel setText:sectionText];
        
        return header;
    } else {
        return nil;
    }
}


#pragma mark - UICollectioViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.previewsArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [[self.nodeList size] integerValue]; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        if (isImage([n name].pathExtension)) {
            MEGAPreview *preview = [MEGAPreview photoWithNode:n];
            preview.caption = [n name];
            [self.previewsArray addObject:preview];
        }
    }
    
    // Get the index of the array using the indexPath
    NSInteger index = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:i];
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *array = [dict objectForKey:key];
        index += array.count;
    }
    
    NSInteger videosCount = 0;
    for (NSInteger i = 0; i < index + indexPath.row; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        if (!isImage([n name].pathExtension)) {
            videosCount++;
        }
    }
    
    index += indexPath.row - videosCount;
    
    MEGANode *node = [self.nodeList nodeAtIndex:(index + videosCount)];
    
    
    if (![self.photosCollectionView allowsMultipleSelection]) {
        if (isImage([node name].pathExtension)) {
            MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            
            photoBrowser.displayActionButton = YES;
            photoBrowser.displayNavArrows = YES;
            photoBrowser.displaySelectionButtons = NO;
            photoBrowser.zoomPhotosToFill = YES;
            photoBrowser.alwaysShowControls = NO;
            photoBrowser.enableGrid = YES;
            photoBrowser.startOnGrid = NO;
            
            // Optionally set the current visible photo before displaying
            //    [browser setCurrentPhotoIndex:1];
            
            [self.navigationController pushViewController:photoBrowser animated:YES];
            
            [photoBrowser showNextPhotoAnimated:YES];
            [photoBrowser showPreviousPhotoAnimated:YES];
            [photoBrowser setCurrentPhotoIndex:index];
        } else if (isMultimedia(node.name.pathExtension)) {
            NSURL *link = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%llu/%lld.%@", [[MEGAProxyServer sharedInstance] port], node.handle, node.name.pathExtension.lowercaseString]];
            if (link) {
                MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:link];
                // Remove the movie player view controller from the "playback did finish" notification observers
                [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController
                                                                name:MPMoviePlayerPlaybackDidFinishNotification
                                                              object:moviePlayerViewController.moviePlayer];
                
                // Register this class as an observer instead
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(movieFinishedCallback:)
                                                             name:MPMoviePlayerPlaybackDidFinishNotification
                                                           object:moviePlayerViewController.moviePlayer];
                
                [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
                
                [moviePlayerViewController.moviePlayer prepareToPlay];
                [moviePlayerViewController.moviePlayer play];
                
                return;
            }
            
        }
    } else {
        if ([self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]]) {
            [self.selectedItemsDictionary removeObjectForKey:[NSNumber numberWithLongLong:node.handle]];
        }
        else {
            [self.selectedItemsDictionary setObject:node forKey:[NSNumber numberWithLongLong:node.handle]];
        }
        
        if ([self.selectedItemsDictionary count]) {
            NSString *message = (self.selectedItemsDictionary.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", nil), self.selectedItemsDictionary.count] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", nil), self.selectedItemsDictionary.count];
            
            [self.navigationItem setTitle:message];
            
            [self.downloadBarButtonItem setEnabled:YES];
            [self.shareBarButtonItem setEnabled:YES];
            [self.moveBarButtonItem setEnabled:YES];
            [self.deleteBarButtonItem setEnabled:YES];
        } else {
            [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
            
            [self.downloadBarButtonItem setEnabled:NO];
            [self.shareBarButtonItem setEnabled:NO];
            [self.moveBarButtonItem setEnabled:NO];
            [self.deleteBarButtonItem setEnabled:NO];
        }
        
        if ([self.selectedItemsDictionary count] == self.nodeList.size.integerValue) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
        
        [self.photosCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]]];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(([UIScreen mainScreen].bounds.size.width-itemsPerRow-1)/itemsPerRow,([UIScreen mainScreen].bounds.size.width-itemsPerRow-1)/itemsPerRow);
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            return nil;
        }
        
        text = AMLocalizedString(@"cameraUploadsEmptyState_title", @"Camera Uploads is disabled.");
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaBlack};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            return nil;
        }
        
        text = AMLocalizedString(@"cameraUploadsEmptyState_text", @"Enable Camera Uploads to have a copy of your photos on MEGA");
    } else {
        text = @"";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:14.0],
                                 NSForegroundColorAttributeName:megaGray,
                                 NSParagraphStyleAttributeName:paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    
    if ([MEGAReachabilityManager isReachable]) {
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            return nil;
        }
        
        return [UIImage imageNamed:@"emptyCameraUploads"];
    } else {
        return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        return nil;
    }
    
    return [UIColor whiteColor];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.previewsArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.previewsArray.count) {
        return [self.previewsArray objectAtIndex:index];
    }
    
    return nil;
}

#pragma mark - Moview player

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    MPMoviePlayerController *moviePlayer = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Move to rubbish bin
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            remainingOperations = self.selectedItemsDictionary.count;
            for (NSInteger i = 0; i < self.selectedItemsDictionary.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] moveNode:[[self.selectedItemsDictionary allValues] objectAtIndex:i] newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:self];
            }
        }
    } else {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeExport:
            [SVProgressHUD showWithStatus:AMLocalizedString(@"generatingLink", @"Generating link...")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrFile: {
            for (PhotoCollectionViewCell *pcvc in [self.photosCollectionView visibleCells]) {
                if ([request nodeHandle] == [pcvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbs"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [pcvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            break;
        }
            
            
        case MEGARequestTypeMove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedItemsDictionary.count <= 1 ) ? AMLocalizedString(@"fileMovedToRubbishBin", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesMovedToRubbishBin", nil), self.selectedItemsDictionary.count];
                [SVProgressHUD showSuccessWithStatus:message];
//                [self setEditing:NO animated:NO];
            }
            break;
        }
            
        case MEGARequestTypeExport: {
            remainingOperations--;
            
            MEGANode *n = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            
            NSString *name = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"fileName", nil), n.name];
            
            NSString *size = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"fileSize", nil), n.isFile ? [NSByteCountFormatter stringFromByteCount:[[n size] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory] : AMLocalizedString(@"folder", nil)];
            
            NSString *link = [request link];
            
            NSArray *tempArray = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@ \n %@ \n %@\n", name, size, link], nil];
            [exportLinks addObjectsFromArray:tempArray];
            
            if (remainingOperations == 0) {
                [SVProgressHUD dismiss];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:exportLinks applicationActivities:nil];
                activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
                [self presentViewController:activityVC animated:YES completion:nil ];
                [self setEditing:NO animated:NO];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeUpload) {
        if (self.uploadProgressViewTopLayoutConstraint.constant == -60) {
            [self showProgressView];
        }
        [self.photoNameLabel setText:[transfer fileName]];
        float percentage = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
        [self.transferredBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer transferredBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.totalBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer totalBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.speedLabel setText:[NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]]];
        [self.progressView setProgress:percentage];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([[[CameraUploads syncManager] assetUploadArray] count] == 1) {
        [self hideProgressView];
    }
}

@end
