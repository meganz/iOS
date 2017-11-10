
#import "MEGAMoveRequestDelegate.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"

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
    [super onRequestStart:api request:request];
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
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
        
        if (self.moveToTheRubbishBin) {
            NSString *message;
            if (self.numberOfFiles == 0) {
                if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"folderMovedToRubbishBinMessage", @"Success message shown when you have moved 1 folder to the rubbish bin");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"foldersMovedToRubbishBinMessage", @"Success message shown when you have moved {1+} folders to the rubbish bin"), self.numberOfFolders];
                }
            } else if (self.numberOfFiles == 1) {
                if (self.numberOfFolders == 0) {
                    message = AMLocalizedString(@"fileMovedToRubbishBinMessage", @"Success message shown when you have moved 1 file to the rubbish bin");
                } else if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"fileFolderMovedToRubbishBinMessage", @"Success message shown when you have moved 1 file and 1 folder to the rubbish bin");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"fileFoldersMovedToRubbishBinMessage", @"Success message shown when you have moved 1 file and {1+} folders to the rubbish bin"), self.numberOfFolders];
                }
            } else {
                if (self.numberOfFolders == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"filesMovedToRubbishBinMessage", @"Success message shown when you have moved {1+} files to the rubbish bin"), self.numberOfFiles];
                } else if (self.numberOfFolders == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"filesFolderMovedToRubbishBinMessage", @"Success message shown when you have moved {1+} files and 1 folder to the rubbish bin"), self.numberOfFiles];
                } else {
                    message = AMLocalizedString(@"filesFoldersMovedToRubbishBinMessage", @"Success message shown when you have moved [A] = {1+} files and [B] = {1+} folders to the rubbish bin");
                    NSString *filesString = [NSString stringWithFormat:@"%lu", self.numberOfFiles];
                    NSString *foldersString = [NSString stringWithFormat:@"%lu", self.numberOfFolders];
                    message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                    message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                }
            }
            
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudRubbishBin"] status:message];
        } else {
            NSString *message;
            if (self.numberOfFiles == 0) {
                if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"moveFolderMessage", @"Success message shown when you have moved 1 folder");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFoldersMessage", @"Success message shown when you have moved {1+} folders"), self.numberOfFolders];
                }
            } else if (self.numberOfFiles == 1) {
                if (self.numberOfFolders == 0) {
                    message = AMLocalizedString(@"moveFileMessage", @"Success message shown when you have moved 1 file");
                } else if (self.numberOfFolders == 1) {
                    message = AMLocalizedString(@"moveFileFolderMessage", @"Success message shown when you have moved 1 file and 1 folder");
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFileFoldersMessage", @"Success message shown when you have moved 1 file and {1+} folders"), self.numberOfFolders];
                }
            } else {
                if (self.numberOfFolders == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesMessage", @"Success message shown when you have moved {1+} files"), self.numberOfFiles];
                } else if (self.numberOfFolders == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesFolderMessage", @"Success message shown when you have moved {1+} files and 1 folder"), self.numberOfFiles];
                } else {
                    message = AMLocalizedString(@"moveFilesFoldersMessage", @"Success message shown when you have moved [A] = {1+} files and [B] = {1+} folders");
                    NSString *filesString = [NSString stringWithFormat:@"%lu", self.numberOfFiles];
                    NSString *foldersString = [NSString stringWithFormat:@"%lu", self.numberOfFolders];
                    message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                    message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                }
            }
            
            [SVProgressHUD showSuccessWithStatus:message];
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
