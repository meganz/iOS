#import "MEGAImagePickerController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGASdk+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "MEGA-Swift.h"

@import ChatRepo;
#import "LocalizationHelper.h"
@import MEGAAppSDKRepo;

@interface MEGAImagePickerController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, getter=toUploadSomething) BOOL uploadSomething;
@property (nonatomic) MEGANode *parentNode;
@property (nonatomic) AssetCreationRequestLocationManagerOCWrapper *assetCreationRequestLocationManager;

@property (nonatomic, getter=toChangeAvatar) BOOL changeAvatar;

@property (nonatomic, getter=toShareThroughChat) BOOL shareThroughChat;
@property (nonatomic, copy) void (^filePathCompletion)(NSString *filePath, UIImagePickerControllerSourceType sourceType, MEGANode *myChatFilesNode);
@property (nonatomic) NSString *filePath;

@end

@implementation MEGAImagePickerController

- (instancetype)initToUploadWithParentNode:(MEGANode *)parentNode sourceType:(UIImagePickerControllerSourceType)sourceType {
    self = [super init];
    
    if (self) {
        _uploadSomething = YES;
        _parentNode = parentNode;
        self.sourceType  = sourceType;
    }
    
    return self;
}

- (instancetype)initToUploadWithParentNodeHandle:(MEGAHandle)parentNodeHandle
                                      sourceType:(UIImagePickerControllerSourceType)sourceType {
    return [self initToUploadWithParentNode:[MEGASdk.shared nodeForHandle:parentNodeHandle] sourceType:sourceType];
}
- (instancetype)initToChangeAvatarWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    self = [super init];
    
    if (self) {
        _changeAvatar = YES;
        self.sourceType  = sourceType;
    }
    
    return self;
}

- (instancetype)initToShareThroughChatWithSourceType:(UIImagePickerControllerSourceType)sourceType filePathCompletion:(void (^)(NSString *filePath, UIImagePickerControllerSourceType sourceType, MEGANode *myChatFilesNode))filePathCompletion {
    self = [super init];
    
    if (self) {
        _shareThroughChat = YES;
        _filePathCompletion = filePathCompletion;
        self.sourceType = sourceType;
    }
    
    return self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (![UIImagePickerController isSourceTypeAvailable:self.sourceType]) {
        if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
            [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudNoCamera"] status:LocalizedString(@"noCamera", @"Error message shown when there's no camera available on the device")];
        }
        return;
    }
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.mediaTypes = [self mediaTypes];
    self.videoQuality = UIImagePickerControllerQualityTypeHigh;
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self initializeAndRequestCameraLocationPermission];
}

- (void)initializeAndRequestCameraLocationPermission {
    if (_assetCreationRequestLocationManager == nil) {
        _assetCreationRequestLocationManager = [[AssetCreationRequestLocationManagerOCWrapper alloc] init];
    }
    [self.assetCreationRequestLocationManager requestWhenInUseAuthorization];
}

#pragma mark - Private

- (NSArray<NSString *> *)mediaTypes {
    if (self.toChangeAvatar || MEGAChatSdk.shared.mnz_existsActiveCall ) {
        return [NSArray.alloc initWithObjects:UTTypeImage.identifier, nil];
    } else {
        return [UIImagePickerController availableMediaTypesForSourceType:self.sourceType];
    }
}

- (NSString *)createAvatarWithImagePath:(NSString *)imagePath {
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([MEGASdk.shared createAvatar:imagePath destinationPath:avatarFilePath]) {
        return avatarFilePath;
    } else {
        return nil;
    }
}

- (void)triggerPathCompletion:(MEGANode *)myChatFilesNode {
    [self dismissViewControllerAnimated:NO completion:nil];
    
    if (self.filePathCompletion) {
        self.filePathCompletion(self.filePath, self.sourceType, myChatFilesNode);
    }
}

- (void)actionForImagePath:(NSString *)imagePath {
    if (self.toUploadSomething) {
        self.filePath = imagePath.mnz_relativeLocalPath;
        [self dismissViewControllerAnimated:YES completion:^{
            CancellableTransfer *transfer = [CancellableTransfer.alloc initWithHandle:MEGAInvalidHandle parentHandle:self.parentNode.handle fileLinkURL:nil localFileURL:[NSURL fileURLWithPath:self.filePath] name:nil appData:nil priority:NO isFile:YES type:CancellableTransferTypeUpload];
            [CancellableTransferRouterOCWrapper.alloc.init uploadFiles:@[transfer] presenter:UIApplication.mnz_visibleViewController type:CancellableTransferTypeUpload];
        }];
    } else if (self.toChangeAvatar) {
        NSString *avatarFilePath = [self createAvatarWithImagePath:imagePath];
        [MEGASdk.shared setAvatarUserWithSourceFilePath:avatarFilePath];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.toShareThroughChat) {
        [MEGASdk.shared createPreview:imagePath destinatioPath:imagePath];
        self.filePath = imagePath.mnz_relativeLocalPath;
        __weak __typeof__(self) weakSelf = self;
        [MyChatFilesFolderNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable myChatFilesFolderNode, NSError * _Nullable error) {
            if (error || myChatFilesFolderNode == nil) {
                MEGALogWarning(@"Coud not load MyChatFiles target folder doe tu error %@", error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf triggerPathCompletion:myChatFilesFolderNode];
            });
        }];
    }
}

- (void)actionForVideo {
    if (self.toUploadSomething) {
        [self dismissViewControllerAnimated:YES completion:^{
            CancellableTransfer *transfer = [CancellableTransfer.alloc initWithHandle:MEGAInvalidHandle parentHandle:self.parentNode.handle fileLinkURL:nil localFileURL:[NSURL fileURLWithPath:self.filePath] name:nil appData:nil priority:NO isFile:YES type:CancellableTransferTypeUpload];
            [CancellableTransferRouterOCWrapper.alloc.init uploadFiles:@[transfer] presenter:UIApplication.mnz_visibleViewController type:CancellableTransferTypeUpload];
        }];
    } else if (self.toShareThroughChat) {
        __weak __typeof__(self) weakSelf = self;
        [MyChatFilesFolderNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable myChatFilesFolderNode, NSError * _Nullable error) {
            if (error || myChatFilesFolderNode == nil) {
                MEGALogWarning(@"Coud not load MyChatFiles target folder doe tu error %@", error);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf triggerPathCompletion:myChatFilesFolderNode];
            });
        }];
    }
}

- (void)createAssetType:(PHAssetResourceType)type filePath:(NSString *)filePath {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *assetCreationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [assetCreationRequest addResourceWithType:type fileURL:fileURL options:nil];
        [self.assetCreationRequestLocationManager registerLocationMetaDataTo:assetCreationRequest];
    } completionHandler:^(BOOL success, NSError * _Nullable nserror) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (type) {
                    case PHAssetResourceTypePhoto:
                        [self actionForImagePath:filePath];
                        break;
                    case PHAssetResourceTypeVideo:
                        [self actionForVideo];
                        break;
                        
                    default:
                        break;
                }
            });
        } else {
            MEGALogError(@"Creation request for asset failed: %@ (Domain: %@ - Code:%td)", nserror.localizedDescription, nserror.domain, nserror.code);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UTType *mediaType = [UTType typeWithIdentifier:[info objectForKey:UIImagePickerControllerMediaType]];
    
    if ([mediaType isEqual:UTTypeImage]) {
        NSString *imageName = [NSString stringWithFormat:@"%@.jpg", NSDate.date.mnz_formattedDefaultNameForMedia];
        NSString *imagePath = (self.toUploadSomething || self.toShareThroughChat) ? [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:imageName] : [NSTemporaryDirectory() stringByAppendingPathComponent:imageName];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [imageData writeToFile:imagePath atomically:YES];
        
        //If the app has 'Read and Write' access to Photos and the user didn't configure the setting to save the media captured from the MEGA app in Photos, enable it by default.
        if (![self hasSetIsSaveMediaCapturedToGalleryEnabled]) {
            [self setIsSaveMediaCapturedToGalleryEnabled:YES];
        }
        
        if (self.sourceType == UIImagePickerControllerSourceTypeCamera && [self getIsSaveMediaCapturedToGalleryEnabled]) {
            [self createAssetType:PHAssetResourceTypePhoto filePath:imagePath];
        } else {
            [self actionForImagePath:imagePath];
        }
    } else if ([mediaType isEqual:UTTypeMovie]) {
        NSURL *videoUrl = (NSURL *)[info objectForKey:UIImagePickerControllerMediaURL];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:videoUrl.path error:nil];
        NSDate *modificationDate = [attributesDictionary objectForKey:NSFileModificationDate];
        NSString *videoName = [modificationDate.mnz_formattedDefaultNameForMedia stringByAppendingPathExtension:@"mov"];
        NSString *localFilePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:videoName];
        NSError *error = nil;
        
        self.filePath = localFilePath.mnz_relativeLocalPath;
        if ([[NSFileManager defaultManager] moveItemAtPath:videoUrl.path toPath:localFilePath error:&error]) {
            //If the app has 'Read and Write' access to Photos and the user didn't configure the setting to save the media captured from the MEGA app in Photos, enable it by default.
            if (![self hasSetIsSaveMediaCapturedToGalleryEnabled]) {
                [self setIsSaveMediaCapturedToGalleryEnabled:YES];
            }
            
            if ([self getIsSaveMediaCapturedToGalleryEnabled]) {
                [self createAssetType:PHAssetResourceTypeVideo filePath:localFilePath];
            } else {
                [self actionForVideo];
            }
        } else {
            MEGALogError(@"Move item at path failed with error: %@", error);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
