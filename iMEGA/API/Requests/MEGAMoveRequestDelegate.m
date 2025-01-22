#import "MEGAMoveRequestDelegate.h"

#import "SVProgressHUD.h"

@import MEGAL10nObjc;

#import "MEGA-Swift.h"

@interface MEGAMoveRequestDelegate ()

@property (nonatomic) NSUInteger numberOfFiles;
@property (nonatomic) NSUInteger numberOfFolders;
@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGAMoveRequestDelegate

#pragma mark - Initialization

- (instancetype)initToMoveToTheRubbishBinWithFiles:(NSUInteger)files folders:(NSUInteger)folders completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfFiles = files;
        _numberOfFolders = folders;
        _numberOfRequests = (_numberOfFiles + _numberOfFolders);
        _totalRequests = (_numberOfFiles + _numberOfFolders);
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    self.numberOfRequests--;
    
    if (error.type != MEGAErrorTypeApiEBusinessPastDue && error.type != MEGAErrorTypeApiEOverQuota) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        NSString *message = [RemovalConfirmationMessageGenerator messageForRemovedFiles:self.numberOfFiles andFolders:self.numberOfFolders];
        [SVProgressHUD showImage:[UIImage imageNamed:@"rubbishBin"] status:message];
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
