
#import "MEGAMoveRequestDelegate.h"

#import "SVProgressHUD.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface MEGAMoveRequestDelegate ()

@property (nonatomic) NSUInteger numberOfFiles;
@property (nonatomic) NSUInteger numberOfFolders;
@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, copy) void (^completion)(void);

@property (nonatomic) BOOL moveToTheRubbishBin;

@end

@implementation MEGAMoveRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _moveToTheRubbishBin = NO;
        _numberOfFiles = files;
        _numberOfFolders = folders;
        _numberOfRequests = (_numberOfFiles + _numberOfFolders);
        _totalRequests = (_numberOfFiles + _numberOfFolders);
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initToMoveToTheRubbishBinWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _moveToTheRubbishBin = YES;
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
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    self.numberOfRequests--;
    
    if (error.type) {        
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        if ((error.type == MEGAErrorTypeApiEBusinessPastDue) || (error.type == MEGAErrorTypeApiEOverQuota)) {
            [SVProgressHUD dismiss];
        } else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, NSLocalizedString(error.name, nil)]];
        }
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (self.moveToTheRubbishBin) {
            NSString *message = [RemovalConfirmationMessageGenerator messageForRemovedFiles:self.numberOfFiles andFolders:self.numberOfFolders];
            [SVProgressHUD showImage:[UIImage imageNamed:@"rubbishBin"] status:message];
        } else {
            if (self.restore) {
                [SVProgressHUD dismiss];
            } else {
                NSString *message;
                if (self.numberOfFiles == 0) {
                    if (self.numberOfFolders == 1) {
                        message = NSLocalizedString(@"moveFolderMessage", @"Success message shown when you have moved 1 folder");
                    } else {
                        message = [NSString stringWithFormat:NSLocalizedString(@"moveFoldersMessage", @"Success message shown when you have moved {1+} folders"), self.numberOfFolders];
                    }
                } else if (self.numberOfFiles == 1) {
                    if (self.numberOfFolders == 0) {
                        message = NSLocalizedString(@"moveFileMessage", @"Success message shown when you have moved 1 file");
                    } else if (self.numberOfFolders == 1) {
                        message = NSLocalizedString(@"moveFileFolderMessage", @"Success message shown when you have moved 1 file and 1 folder");
                    } else {
                        message = [NSString stringWithFormat:NSLocalizedString(@"moveFileFoldersMessage", @"Success message shown when you have moved 1 file and {1+} folders"), self.numberOfFolders];
                    }
                } else {
                    if (self.numberOfFolders == 0) {
                        message = [NSString stringWithFormat:NSLocalizedString(@"moveFilesMessage", @"Success message shown when you have moved {1+} files"), self.numberOfFiles];
                    } else if (self.numberOfFolders == 1) {
                        message = [NSString stringWithFormat:NSLocalizedString(@"moveFilesFolderMessage", @"Success message shown when you have moved {1+} files and 1 folder"), self.numberOfFiles];
                    } else {
                        message = NSLocalizedString(@"moveFilesFoldersMessage", @"Success message shown when you have moved [A] = {1+} files and [B] = {1+} folders");
                        NSString *filesString = [NSString stringWithFormat:@"%tu", self.numberOfFiles];
                        NSString *foldersString = [NSString stringWithFormat:@"%tu", self.numberOfFolders];
                        message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                        message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                    }
                }
                
                [SVProgressHUD showSuccessWithStatus:message];
            }
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
