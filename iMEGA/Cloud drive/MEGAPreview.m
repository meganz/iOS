/**
 * @file MEGAPreview.m
 * @brief Photo preview of an image.
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
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

#import "MEGAPreview.h"
#import "SVProgressHUD.h"
#import "Helper.h"

#import "MEGAStore.h"

@interface MEGAPreview () <MWPhoto, MEGARequestDelegate, MEGATransferDelegate> {

    BOOL _isLoading;

}

- (void)imageLoaded;

@end

@implementation MEGAPreview


#pragma mark - Class Methods

+ (MEGAPreview *)photoWithNode:(MEGANode *)node {
    return [[MEGAPreview alloc] initWithNode:node];
}


#pragma mark - Init

- (id)initWithNode:(MEGANode*)node {
    self = [super init];
    if (self) {
        _node = node;
    }
    return self;
}

#pragma mark - MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    self.imagePath = [Helper pathForNode:self.node searchPath:NSCachesDirectory directory:@"previewsV3"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:self.imagePath]) {
        return nil;
    }
    
    return [UIImage imageWithContentsOfFile:self.imagePath];
}

- (void)loadUnderlyingImageAndNotify {
  
    if(_isLoading) return;
    
    _isLoading = YES;
    
    if(self.underlyingImage)
        [self imageLoaded];
    else
        [self performLoadUnderlyingImageAndNotify];
    
}

- (void)performLoadUnderlyingImageAndNotify {
    if([self.node hasPreview]) {
        if (self.isFromFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] getPreviewNode:self.node destinationFilePath:self.imagePath delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] getPreviewNode:self.node destinationFilePath:self.imagePath delegate:self];
        }
    } else {
        
        NSString *offlineImagePath  = [[Helper pathForOffline] stringByAppendingPathComponent:[[MEGASdkManager sharedMEGASdk] escapeFsIncompatible:[self.node name]]];
        if (self.isFromFolderLink) {
            [[MEGASdkManager sharedMEGASdkFolder] startDownloadNode:self.node localPath:offlineImagePath delegate:self];
        } else {
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:self.node localPath:offlineImagePath delegate:self];
        }
    }
}

- (void)unloadUnderlyingImage {

}

- (void)imageLoaded {
    _isLoading = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION object:self];
}


#pragma mark - MEGARequestDelegate


- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error{
    self.caption = [self.node name];
    [self performSelector:@selector(imageLoaded) withObject:nil afterDelay:0];

}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error{
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [[Helper downloadingNodes] removeObjectForKey:[MEGASdk base64HandleForHandle:[transfer nodeHandle]]];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    float progress = [transfer.transferredBytes floatValue] / [transfer.totalBytes floatValue];
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat:progress], @"progress",
                          self, @"photo", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    self.caption = [self.node name];
    [self performSelector:@selector(imageLoaded) withObject:nil afterDelay:0];
    
    [[NSFileManager defaultManager] removeItemAtPath:[transfer path] error:nil];
    
    MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:transfer.path]];
    if (offlineNode) {
        [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
    }
}

@end


