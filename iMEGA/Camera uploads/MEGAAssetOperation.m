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

@interface MEGAAssetOperation () <MEGATransferDelegate, MEGARequestDelegate> {
    BOOL executing;
    BOOL finished;
}

@property (nonatomic, strong) PHAsset *phasset;
@property (nonatomic, strong) ALAsset *alasset;
@property (nonatomic, strong) MEGANode *cameraUploadNode;
@property (assign) uint64_t cameraUploadsHandle;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation MEGAAssetOperation

- (instancetype)initWithPHAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode cameraUploadsHandle:(uint64_t)cameraUploadsHandle {
    if (self = [super init]) {
        _phasset = asset;
        _alasset = nil;
        _cameraUploadNode = cameraUploadNode;
        _cameraUploadsHandle = cameraUploadsHandle;
        executing = NO;
        finished = NO;
    }
    return self;
}

- (instancetype)initWithALAsset:(ALAsset *)asset cameraUploadNode:(MEGANode *)cameraUploadNode cameraUploadsHandle:(uint64_t)cameraUploadsHandle {
    if (self = [super init]) {
        _phasset = nil;
        _alasset = asset;
        _cameraUploadNode = cameraUploadNode;
        _cameraUploadsHandle = cameraUploadsHandle;
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
        [self checkiOS9PHAsset];
    }
    
    if (_alasset) {
        [self checkiOS7AndiOS8Asset];
    }
}

#pragma mark - Private methods

- (void)checkiOS9PHAsset {
    if (![[NSFileManager defaultManager] fileExistsAtPath:NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:NSTemporaryDirectory() withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSArray <PHAssetResource *> *assetResources = [PHAssetResource assetResourcesForAsset:_phasset];
    
    NSString *extension = [[[[assetResources objectAtIndex:0] originalFilename] pathExtension] lowercaseString];
    NSString *name = [[_dateFormatter stringFromDate:_phasset.creationDate] stringByAppendingPathExtension:extension];
    NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:nil];
    }
    
    [[PHAssetResourceManager defaultManager]
     writeDataForAssetResource:[assetResources objectAtIndex:0]
     toFile:[NSURL fileURLWithPath:localFilePath]
     options:nil
     completionHandler:^(NSError *error) {
         if (error.code == -1) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                     message:AMLocalizedString(@"cameraUploadsDisabled_alertView_message", @"Camera Uploads will be disabled, because you don't have enought space on your device")
                                                                    delegate:self
                                                           cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                           otherButtonTitles:nil];
                 [alertView show];
             });
             
             [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
             return;
         }
         
         if (!error) {
             NSError *errorChangeFileDate = nil;
             NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:_phasset.creationDate forKey:NSFileModificationDate];
             [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&errorChangeFileDate];
             if (errorChangeFileDate) {
                 [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
             }
             
             NSString *localFingerPrint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:localFilePath];
             
             MEGANode *nodeExists = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerPrint parent:_cameraUploadNode];
             
             if (nodeExists == nil) {
                 NSString *localCRC = [[MEGASdkManager sharedMEGASdk] CRCForFingerprint:localFingerPrint];
                 nodeExists = [[MEGASdkManager sharedMEGASdk] nodeByCRC:localCRC parent:_cameraUploadNode];
             }
             
             if (nodeExists == nil) {
                 NSString *newName = [self newNameForName:name];
                 
                 if (![name isEqualToString:newName]) {
                     NSString *newLocalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];
                     
                     NSError *error = nil;
                     [[NSFileManager defaultManager] moveItemAtPath:localFilePath toPath:newLocalFilePath error:&error];
                     if (error) {
                         [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
                     }
                     [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newLocalFilePath parent:_cameraUploadNode delegate:self];
                 } else {
                     [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:_cameraUploadNode delegate:self];
                 }
             } else {
                 if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:nodeExists] handle] != _cameraUploadsHandle) {
                     NSString *newName = [self newNameForName:name];
                     
                     if (![name isEqualToString:newName]) {
                         [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:_cameraUploadNode newName:newName delegate:self];
                     } else {
                         [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:_cameraUploadNode newName:name delegate:self];
                     }
                 } else {
                     if (![nodeExists.name isEqualToString:name] && [[nodeExists.name stringByDeletingPathExtension] rangeOfString:[name stringByDeletingPathExtension]].location == NSNotFound) {
                         NSString *newName = [self newNameForName:name];
                         
                         if (![name isEqualToString:newName]) {
                             [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:newName delegate:self];
                         } else {
                             [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:name delegate:self];
                         }
                     } else {
                         [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:nil];
                         [self completeOperation];
                         if ([[[CameraUploads syncManager] assetsOperationQueue] operationCount] == 1) {
                             [[CameraUploads syncManager] resetOperationQueue];
                         }
                     }
                 }
             }
         }
     }];
}

- (void)checkiOS7AndiOS8Asset {
    NSDate *creationDate = [_alasset valueForProperty:ALAssetPropertyDate];
    NSString *extension = [[[[[_alasset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
    NSString *name = [[_dateFormatter stringFromDate:creationDate] stringByAppendingPathExtension:extension];
    NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    ALAssetRepresentation *assetRepresentation = [_alasset defaultRepresentation];
    NSString *localFingerPrint = [[MEGASdkManager sharedMEGASdk] fingerprintForAssetRepresentation:assetRepresentation modificationTime:creationDate];
    
    MEGANode *nodeExists = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerPrint parent:_cameraUploadNode];
    
    if (nodeExists == nil) {
        NSString *localCRC = [[MEGASdkManager sharedMEGASdk] CRCForFingerprint:localFingerPrint];
        nodeExists = [[MEGASdkManager sharedMEGASdk] nodeByCRC:localCRC parent:_cameraUploadNode];
    }
    
    if (nodeExists == nil) {        
        long long asize = assetRepresentation.size;
        long long freeSpace = (long long)[Helper freeDiskSpace];
        
        if (asize > freeSpace) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                    message:AMLocalizedString(@"cameraUploadsDisabled_alertView_message", @"Camera Uploads will be disabled, because you don't have enought space on your device")
                                                                   delegate:self
                                                          cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                [alertView show];
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
            });
            
            return;
        }
        
        [[NSFileManager defaultManager] createFileAtPath:localFilePath contents:nil attributes:nil];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:localFilePath];
        
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
        
        NSError *error = nil;
        NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:creationDate forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
        if (error) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
        }
        
        NSString *newName = [self newNameForName:name];
        
        if (![name isEqualToString:newName]) {
            NSString *newLocalFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtPath:localFilePath toPath:newLocalFilePath error:&error];
            if (error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:newLocalFilePath parent:_cameraUploadNode delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:_cameraUploadNode delegate:self];
        }
    } else {
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:nodeExists] handle] != _cameraUploadsHandle) {
            NSString *newName = [self newNameForName:name];
            
            if (![name isEqualToString:newName]) {
                [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:_cameraUploadNode newName:newName delegate:self];
            } else {
                [[MEGASdkManager sharedMEGASdk] copyNode:nodeExists newParent:_cameraUploadNode newName:name delegate:self];
            }
        } else {
            if (![nodeExists.name isEqualToString:name] && [[nodeExists.name stringByDeletingPathExtension] rangeOfString:[name stringByDeletingPathExtension]].location == NSNotFound) {
                NSString *newName = [self newNameForName:name];
                
                if (![name isEqualToString:newName]) {
                    [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:newName delegate:self];
                } else {
                    [[MEGASdkManager sharedMEGASdk] renameNode:nodeExists newName:name delegate:self];
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

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeCopy:
        case MEGARequestTypeRename: {
            [[CameraUploads syncManager] setBadgeValue];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCopy:
        case MEGARequestTypeRename: {
            [self completeOperation];
            [[CameraUploads syncManager] setBadgeValue];
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
    [[NSFileManager defaultManager] removeItemAtPath:transfer.path error:nil];
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEArgs) {
            [[CameraUploads syncManager] resetOperationQueue];
        }
        return;
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
