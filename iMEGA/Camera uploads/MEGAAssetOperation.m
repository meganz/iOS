#import "MEGAAssetOperation.h"
#import "Helper.h"
#import "CameraUploads.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "MEGAProcessAsset.h"
#import "MEGAReachabilityManager.h"

@interface MEGAAssetOperation () <MEGATransferDelegate, MEGARequestDelegate> {
    BOOL executing;
    BOOL finished;
}

@property (nonatomic, strong) PHAsset *phasset;
@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, assign) BOOL automatically;
@property (nonatomic, copy) NSString *uploadsDirectory; // Local directory

@end

@implementation MEGAAssetOperation

- (instancetype)initWithPHAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode automatically:(BOOL)automatically {
    if (self = [super init]) {
        _phasset = asset;
        _parentNode = parentNode;
        executing = NO;
        finished = NO;
        _automatically = automatically;
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
    self.uploadsDirectory = [[NSFileManager defaultManager] uploadsDirectory];
    
    if (self.automatically) {
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
    }
    
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self main];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initWithAsset:self.phasset parentNode:self.parentNode filePath:^(NSString *filePath) {
        NSString *name = filePath.lastPathComponent;
        NSString *newName = [self newNameForName:name];
        
        NSString *appData = nil;
        if (self.automatically) {
            appData = [NSString stringWithFormat:@"CU=%ld", [[[CameraUploads syncManager] assetsOperationQueue] operationCount]];
        }
        
        if (![name isEqualToString:newName]) {
            NSString *newFilePath = [self.uploadsDirectory stringByAppendingPathComponent:newName];
            
            NSError *error = nil;
            NSString *absoluteFilePath = [NSHomeDirectory() stringByAppendingPathComponent:filePath];
            if (![[NSFileManager defaultManager] moveItemAtPath:absoluteFilePath toPath:newFilePath error:&error]) {
                MEGALogError(@"Move item at path failed with error: %@", error);
            }
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[newFilePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:appData isSourceTemporary:YES delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[filePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:appData isSourceTemporary:YES delegate:self];
        }
    } node:^(MEGANode *node) {
        if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:node] handle] == self.parentNode.handle) {
            MEGALogDebug(@"The asset exists in MEGA in the parent folder");
            [self completeOperation];
            if ([[[CameraUploads syncManager] assetsOperationQueue] operationCount] == 1 && self.automatically) {
                [[CameraUploads syncManager] resetOperationQueue];
            }
        } else {
            [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.parentNode delegate:self];
        }
    } error:^(NSError *error) {
        [self manageError:error];
    }];
    [processAsset prepare];
}

#pragma mark - Private

- (NSString *)newNameForName:(NSString *)name {
    NSString *nameWithoutExtension = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];
    int index = 0;
    int listSize = 0;
    
    do {
        if (index != 0) {
            nameWithoutExtension = [[name stringByDeletingPathExtension] stringByAppendingString:[NSString stringWithFormat:@"_%d", index]];
        }
        
        MEGANodeList *nameNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:self.parentNode searchString:[nameWithoutExtension stringByAppendingPathExtension:extension]];
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
    
    if (self.automatically) {
        if (self.phasset) {
            if (self.phasset.mediaType == PHAssetMediaTypeImage) {
                [[NSUserDefaults standardUserDefaults] setObject:self.phasset.creationDate forKey:kLastUploadPhotoDate];
            }
            
            if (self.phasset.mediaType == PHAssetMediaTypeVideo) {
                [[NSUserDefaults standardUserDefaults] setObject:self.phasset.creationDate forKey:kLastUploadVideoDate];
            }
        }
    }
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)disableCameraUploadsWithError:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"%@ (Domain: %@ - Code:%ld)", error.localizedDescription, error.domain, (long)error.code];
    MEGALogDebug(@"Disable Camera Uploads: %@", message);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"cameraUploadsWillBeDisabled", nil)
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
    });
}

- (void)manageError:(NSError *)error {
    if ([error.domain isEqualToString:MEGAProcessAssetErrorDomain]) {
        if (error.code == - 2 && self.automatically) {
            [self disableCameraUploadsWithError:error];
        }
    } else {
        switch (error.code) {
            case 0:
            case 1:
            case 27:
            case 28:
            case 80:
            case 81:
            case 150:
            case 1000: {
                [self completeOperation];
                break;
            }
                
            case 25:
                [self completeOperation];
                break;
                
            case 640: {
                if (self.automatically) {
                    [self disableCameraUploadsWithError:error];
                }
                break;
            }
                
            default: {
                if (self.automatically) {
                    [self disableCameraUploadsWithError:error];
                }
                break;
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
            [self completeOperation];
            break;
            
        default:
            break;
    }
    
    if (![[[CameraUploads syncManager] assetsOperationQueue] operationCount] && self.automatically) {
        [[CameraUploads syncManager] resetOperationQueue];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([self isCancelled]) {
        [[MEGASdkManager sharedMEGASdk] cancelTransfer:transfer];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEIncomplete) {
            if (self.automatically) {
                [self start];
            } else {
                [self completeOperation];
            }
        } else if (self.automatically) {
            [[CameraUploads syncManager] resetOperationQueue];
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeUpload) {
        [self completeOperation];
    }
    
    if (![[[CameraUploads syncManager] assetsOperationQueue] operationCount] && self.automatically) {
        [[CameraUploads syncManager] resetOperationQueue];
    }
}

@end
