#import "MEGARemoveRequestDelegate.h"

#import "SVProgressHUD.h"

#import "DisplayMode.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

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

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    self.numberOfRequests--;
    
    if (error.type) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, LocalizedString(error.name, @"")]];
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (self.mode == DisplayModeCloudDrive || self.mode == DisplayModeRubbishBin) {
            NSString *message = [RemovalConfirmationMessageGenerator messageForRemovedFiles:self.numberOfFiles andFolders:self.numberOfFolders];
            
            [SVProgressHUD showImage:[UIImage megaImageWithNamed:@"hudMinus"] status:message];
        } else if (self.mode == DisplayModeSharedItem) {
            if (self.totalRequests > 1) {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"sharesLeft", @"Message shown when some shares have been left")];
            } else {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"shareLeft", @"Message shown when a share has been left")];
            }
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
