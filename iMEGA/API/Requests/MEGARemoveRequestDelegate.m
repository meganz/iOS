
#import "MEGARemoveRequestDelegate.h"

#import "SVProgressHUD.h"

#import "DisplayMode.h"

@interface MEGARemoveRequestDelegate ()

@property (nonatomic) DisplayMode mode;
@property (nonatomic) NSUInteger numberOfFiles;
@property (nonatomic) NSUInteger numberOfFolders;
@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGARemoveRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithMode:(NSInteger)mode files:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _mode = mode;
        _numberOfFiles = files;
        _numberOfFolders = folders;
        _numberOfRequests = (_numberOfFiles + _numberOfFolders);
        _totalRequests = (_numberOfFiles + _numberOfFolders);
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
    
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, error.name]];
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (self.mode == DisplayModeCloudDrive || self.mode == DisplayModeRubbishBin) {
            NSString *message;
            if (self.numberOfFiles == 0) {
                if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"folderRemovedToRubbishBinMessage", @"Success message shown when 1 folder has been removed from MEGA");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"foldersRemovedToRubbishBinMessage", @"Success message shown when {1+} folders have been removed from MEGA"), self.numberOfFolders];
                }
            } else if (self.numberOfFiles == 1) {
                if (self.numberOfFolders == 0) {
                    message = AMLocalizedString(@"fileRemovedToRubbishBinMessage", @"Success message shown when 1 file has been removed from MEGA");
                } else if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"fileFolderRemovedToRubbishBinMessage", @"Success message shown when 1 file and 1 folder have been removed from MEGA");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"fileFoldersRemovedToRubbishBinMessage", @"Success message shown when 1 file and {1+} folders have been removed from MEGA"), self.numberOfFolders];
                }
            } else {
                if (self.numberOfFolders == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"filesRemovedToRubbishBinMessage", @"Success message shown when {1+} files have been removed from MEGA"), self.numberOfFiles];
                } else if (self.numberOfFolders == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"filesFolderRemovedToRubbishBinMessage", @"Success message shown when {1+} files and 1 folder have been removed from MEGA"), self.numberOfFiles];
                } else {
                    message = AMLocalizedString(@"filesFoldersRemovedToRubbishBinMessage", @"Success message shown when [A] = {1+} files and [B] = {1+} folders have been removed from MEGA");
                    NSString *filesString = [NSString stringWithFormat:@"%lu", self.numberOfFiles];
                    NSString *foldersString = [NSString stringWithFormat:@"%lu", self.numberOfFolders];
                    message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                    message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                }
            }
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
        } else if (self.mode == DisplayModeSharedItem) {
            if (self.totalRequests > 1) {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sharesLeft", @"Message shown when some shares have been left")];
            } else {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"shareLeft", @"Message shown when a share has been left")];
            }
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
