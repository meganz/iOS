/**
 * @file MEGAAssetOperation.m
 * @brief This class checks the action (Upload, copy, rename or ignore) 
 * that should be taken on an asset and perform it
 *
 * (c) 2013-2016 by Mega Limited, Auckland, New Zealand
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

#import "MEGAAssetOperation.h"
#import "Helper.h"
#import "CameraUploads.h"
#import "NSString+MNZCategory.h"
#import "MEGAReachabilityManager.h"

@interface MEGAAssetOperation () <MEGATransferDelegate, MEGARequestDelegate> {
    BOOL executing;
    BOOL finished;
}

@property (nonatomic, strong) PHAsset *phasset;
@property (nonatomic, strong) ALAsset *alasset;
@property (nonatomic, strong) MEGANode *cameraUploadNode;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MEGAAssetOperation

- (instancetype)initWithPHAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode {
    if (self = [super init]) {
        _phasset = asset;
        _alasset = nil;
        _cameraUploadNode = cameraUploadNode;
        executing = NO;
        finished = NO;
    }
    return self;
}

- (instancetype)initWithALAsset:(ALAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode {
    if (self = [super init]) {
        _phasset = nil;
        _alasset = asset;
        _cameraUploadNode = cameraUploadNode;
        executing = NO;
        finished = NO;
    }
    return self;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start {
    if (![CameraUploads syncManager].isCameraUploadsEnabled) {
        [[CameraUploads syncManager] resetOperationQueue];
        return;
    }
    
    if (![CameraUploads syncManager].isUseCellularConnectionEnabled) {
        if ([MEGAReachabilityManager isReachableViaWWAN]) {
            [[CameraUploads syncManager] resetOperationQueue];
            return;
        }
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn] == 0) {
        [[CameraUploads syncManager] resetOperationQueue];
        return;
    }
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [_dateFormatter setLocale:locale];
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
    if (_phasset) {
        [self checkiOS8AndiOS9PHAsset];
    }
    
    if (_alasset) {
        [self checkiOS7ALAsset];
    }
}

#pragma mark - Private methods

- (void)checkiOS8AndiOS9PHAsset {
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (_phasset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionOriginal;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager]
         requestImageDataForAsset:_phasset
         options:options
         resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
             if (!imageData) {
                 NSError *error = [info objectForKey:@"PHImageErrorKey"];
                 if (error) {
                     MEGALogError(@"Request image data for asset: %@", error);
                 }
                 MEGALogDebug(@"There are not image data - Info: %@", info);
                 [self disableCameraUploadWithError:error];
                 return;
             }
             NSString *filePath = [self filePathWithInfo:info];
             NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:_phasset.creationDate];
             MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fingerprint parent:_cameraUploadNode];
             
             [self actionForNode:node fingerPrint:fingerprint filePath:filePath imageData:imageData alassetRepresentation:nil];
         }];
    } else if ((_phasset.mediaType == PHAssetMediaTypeVideo)) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.networkAccessAllowed = YES;
        
        [[PHImageManager defaultManager]
         requestAVAssetForVideo:_phasset
         options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
             if (!asset) {
                 NSError *error = [info objectForKey:@"PHImageErrorKey"];
                 if (error) {
                     MEGALogError(@"Request avasset for video: %@", error);
                 }
                 MEGALogDebug(@"There are not avasset - Info: %@", info);
                 [self disableCameraUploadWithError:error];
                 return;
             }
             if ([asset isKindOfClass:[AVURLAsset class]]) {
                 NSURL *avassetUrl = [(AVURLAsset *)asset URL];
                 NSDictionary *fileAtributes = [[NSFileManager defaultManager] attributesOfItemAtPath:avassetUrl.path error:nil];
                 long long fileSize = [[fileAtributes objectForKey:NSFileSize] longLongValue];
                 
                 if (![self hasFreeSpaceOnDiskForWriteFile:fileSize]) {
                     return;
                 }
                 
                 NSString *filePath = [self filePathWithInfo:info];
                 NSError *error = nil;
                 BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
                 if (![[NSFileManager defaultManager] copyItemAtPath:avassetUrl.path toPath:filePath error:&error] && !fileExists) {
                     if (error) {
                         MEGALogError(@"Copy item at path: %@", error);
                         [self disableCameraUploadWithError:error];
                         return;
                     }
                 }
                 
                 error = nil;
                 NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:_phasset.creationDate forKey:NSFileModificationDate];
                 if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:filePath error:&error]) {
                     MEGALogError(@"Set attributes: %@", error);
                 }
                 
                 NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:filePath];
                 MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fingerprint parent:_cameraUploadNode];
                 
                 [self actionForNode:node fingerPrint:fingerprint filePath:filePath imageData:nil alassetRepresentation:nil];
             }
         }];
        
    }
}

- (void)checkiOS7ALAsset {
    NSDate *creationDate = [_alasset valueForProperty:ALAssetPropertyDate];
    NSString *extension = [[[[[_alasset defaultRepresentation] url] absoluteString] mnz_stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
    NSString *name = [[_dateFormatter stringFromDate:creationDate] stringByAppendingPathExtension:extension];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    ALAssetRepresentation *assetRepresentation = [_alasset defaultRepresentation];
    NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForAssetRepresentation:assetRepresentation modificationTime:creationDate];
    
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fingerprint parent:_cameraUploadNode];
    [self actionForNode:node fingerPrint:fingerprint filePath:filePath imageData:nil alassetRepresentation:assetRepresentation];
}

- (NSString *)newNameForName:(NSString *)name {
    NSString *nameWithoutExtension = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];
    int index = 0;
    int listSize = 0;
    
    do {
        if (index != 0) {
            nameWithoutExtension = [[name stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"_%d", index]];
        }
        
        MEGANodeList *nameNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:_cameraUploadNode searchString:[nameWithoutExtension stringByAppendingPathExtension:extension]];
        listSize = [nameNodeList.size intValue];
        index++;
    } while (listSize != 0);
    
    return [nameWithoutExtension stringByAppendingPathExtension:extension];
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    executing = NO;
    finished = YES;
    
    if (_phasset) {
        if (_phasset.mediaType == PHAssetMediaTypeImage) {
            [[NSUserDefaults standardUserDefaults] setObject:_phasset.creationDate forKey:kLastUploadPhotoDate];
        }
        
        if (_phasset.mediaType == PHAssetMediaTypeVideo) {
            [[NSUserDefaults standardUserDefaults] setObject:_phasset.creationDate forKey:kLastUploadVideoDate];
        }
    }
    
    if (_alasset) {
        if ([[_alasset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
            [[NSUserDefaults standardUserDefaults] setObject:[_alasset valueForProperty:ALAssetPropertyDate] forKey:kLastUploadPhotoDate];
        }
        
        if ([[_alasset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            [[NSUserDefaults standardUserDefaults] setObject:[_alasset valueForProperty:ALAssetPropertyDate] forKey:kLastUploadVideoDate];
        }
    }
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (NSString *)filePathWithInfo:(NSDictionary *)info {
    MEGALogDebug(@"Photo asset info: %@", info);
    NSURL *url = [info objectForKey:@"PHImageFileURLKey"];
    if (!url) {
        url = [info objectForKey:@"PHImageFileSandboxExtensionTokenKey"];
    }
    
    NSString *extension = [[url pathExtension] lowercaseString];
    NSString *name = [[_dateFormatter stringFromDate:_phasset.creationDate] stringByAppendingPathExtension:extension];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    return filePath;
}

- (BOOL)hasFreeSpaceOnDiskForWriteFile:(long long)fileSize {
    long long freeSpace = (long long)[Helper freeDiskSpace];
    if (fileSize > freeSpace) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                message:AMLocalizedString(@"cameraUploadsDisabled_alertView_message", @"Camera Uploads will be disabled, because you don't have enought space on your device")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
        });
        
        return NO;
    }
    return YES;
}

- (void)disableCameraUploadWithError:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"%@ (Domain: %@ - Code:%ld)", error.localizedDescription, error.domain, (long)error.code];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"cameraUploadsEmptyState_title", nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
    });
}

- (void)actionForNode:(MEGANode *)node fingerPrint:(NSString *)fingerprint filePath:(NSString *)filePath imageData:(NSData *)imageData alassetRepresentation:(ALAssetRepresentation *)assetRepresentation {
    NSString *name = [filePath lastPathComponent];
    if (node == nil) {
        NSString *crc = [[MEGASdkManager sharedMEGASdk] CRCForFingerprint:fingerprint];
        node = [[MEGASdkManager sharedMEGASdk] nodeByCRC:crc parent:_cameraUploadNode];
    }
    if (node == nil) {
        if (imageData) {
            long long fileSize = imageData.length;
            if (![self hasFreeSpaceOnDiskForWriteFile:fileSize]) {
                return;
            }
            
            [imageData writeToFile:filePath atomically:YES];
        }
        
        if (assetRepresentation) {
            long long fileSize = assetRepresentation.size;
            if (![self hasFreeSpaceOnDiskForWriteFile:fileSize]) {
                return;
            }
            
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            
            static const NSUInteger kBufferSize = 10 * 1024;
            uint8_t *buffer = calloc(kBufferSize, sizeof(*buffer));
            NSUInteger offset = 0, bytesRead = 0;
            
            do {
                bytesRead = [assetRepresentation getBytes:buffer fromOffset:offset length:kBufferSize error:nil];
                [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
                offset += bytesRead;
            } while (bytesRead > 0);
            
            free(buffer);
            [handle closeFile];
        }
        
        NSError *error = nil;
        NSDictionary *attributesDictionary;
        if (_alasset) {
            attributesDictionary = [NSDictionary dictionaryWithObject:[_alasset valueForProperty:ALAssetPropertyDate] forKey:NSFileModificationDate];
        } else {
            attributesDictionary = [NSDictionary dictionaryWithObject:_phasset.creationDate forKey:NSFileModificationDate];
        }
        
        if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:filePath error:&error]) {
            MEGALogError(@"Set attributes: %@", error);
        }
        
        NSString *newName = [self newNameForName:name];
        
        if (![name isEqualToString:newName]) {
            NSString *newFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            if (![[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newFilePath error:&error]) {
                MEGALogError(@"Move item at path: %@", error);
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newFilePath parent:_cameraUploadNode delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:filePath parent:_cameraUploadNode delegate:self];
        }
    } else {
        if (!imageData && !assetRepresentation) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:node] handle] != _cameraUploadNode.handle) {
            NSString *newName = [self newNameForName:name];
            
            if (![name isEqualToString:newName]) {
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:_cameraUploadNode newName:newName delegate:self];
            } else {
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:_cameraUploadNode newName:name delegate:self];
            }
        } else {
            if (![node.name isEqualToString:name] && [[node.name stringByDeletingPathExtension] rangeOfString:[name stringByDeletingPathExtension]].location == NSNotFound) {
                NSString *newName = [self newNameForName:name];
                
                if (![name isEqualToString:newName]) {
                    [[MEGASdkManager sharedMEGASdk] renameNode:node newName:newName delegate:self];
                } else {
                    [[MEGASdkManager sharedMEGASdk] renameNode:node newName:name delegate:self];
                }
            } else {
                [self completeOperation];
                if ([[[CameraUploads syncManager] assetsOperationQueue] operationCount] == 1) {
                    [[CameraUploads syncManager] resetOperationQueue];
                }
            }
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCopy:
        case MEGARequestTypeRename: {
            [self completeOperation];
            break;
        }
            
        default:
            break;
    }
    
    if (![[[CameraUploads syncManager] assetsOperationQueue] operationCount]) {
        [[CameraUploads syncManager] resetOperationQueue];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeUpload) {
        [[CameraUploads syncManager] setBadgeValue];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([self isCancelled]) {
        [[MEGASdkManager sharedMEGASdk] cancelTransfer:transfer];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [self start];
        } else if ([error type] != MEGAErrorTypeApiEExist) {
            [[CameraUploads syncManager] resetOperationQueue];
        }
        return;
    }
    
    NSError *nserror = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:transfer.path error:&nserror]) {
        MEGALogError(@"Remove item at path: %@", nserror);
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        [self completeOperation];        
        [[CameraUploads syncManager] setBadgeValue];
    }
    
    if (![[[CameraUploads syncManager] assetsOperationQueue] operationCount]) {
        [[CameraUploads syncManager] resetOperationQueue];
    }
}


@end
