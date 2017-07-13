
#import "MEGAImagePickerController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "NSFileManager+MNZCategory.h"

#import "MEGASdkManager.h"

@interface MEGAImagePickerController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, getter=toUploadSomething) BOOL uploadSomething;
@property (nonatomic) MEGANode *parentNode;

@property (nonatomic, getter=toChangeAvatar) BOOL changeAvatar;

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

- (instancetype)initToChangeAvatarWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    self = [super init];
    
    if (self) {
        _changeAvatar = YES;
        self.sourceType  = sourceType;
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
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudNoCamera"] status:AMLocalizedString(@"noCamera", @"Error message shown when there's no camera available on the device")];
        }
        return;
    }
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    if (self.toUploadSomething) {
        self.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
    } else if (self.toChangeAvatar) {
        self.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    }
    self.videoQuality = UIImagePickerControllerQualityTypeHigh;
    self.delegate = self;
}

#pragma mark - Private

- (NSString *)createAvatarWithImagePath:(NSString *)imagePath {
    NSString *base64Handle = [MEGASdk base64HandleForUserHandle:[[[MEGASdkManager sharedMEGASdk] myUser] handle]];
    NSString *avatarFilePath = [[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"] stringByAppendingPathComponent:base64Handle];
    if ([[MEGASdkManager sharedMEGASdk] createAvatar:imagePath destinationPath:avatarFilePath]) {
        return avatarFilePath;
    } else {
        return nil;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss";
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.locale = locale;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]) {
        NSString *imageName = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
        NSString *imagePath = self.toUploadSomething ? [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:imageName] : [NSTemporaryDirectory() stringByAppendingPathComponent:imageName];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [imageData writeToFile:imagePath atomically:YES];
        
        if (self.toUploadSomething) {
            [[MEGASdkManager sharedMEGASdk] createThumbnail:imagePath destinatioPath:[imagePath stringByAppendingString:@"_thumbnail"]];
            [[MEGASdkManager sharedMEGASdk] createPreview:imagePath destinatioPath:[imagePath stringByAppendingString:@"_preview"]];
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[imagePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:nil isSourceTemporary:YES];
        } else if (self.toChangeAvatar) {
            NSString *avatarFilePath = [self createAvatarWithImagePath:imagePath];
            [[MEGASdkManager sharedMEGASdk] setAvatarUserWithSourceFilePath:avatarFilePath];
        }
    } else if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeMovie]) {
        NSURL *videoUrl = (NSURL *)[info objectForKey:UIImagePickerControllerMediaURL];
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:videoUrl.path error:nil];
        NSDate *modificationDate = [attributesDictionary objectForKey:NSFileModificationDate];
        NSString *videoName = [[formatter stringFromDate:modificationDate] stringByAppendingPathExtension:@"mov"];
        NSString *localFilePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:videoName];
        NSError *error = nil;
        if ([[NSFileManager defaultManager] moveItemAtPath:videoUrl.path toPath:localFilePath error:&error]) {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[localFilePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:nil isSourceTemporary:YES];
        } else {
            MEGALogError(@"Move item at path failed with error: %@", error);
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
