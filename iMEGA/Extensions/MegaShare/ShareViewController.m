
#import "ShareViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "LaunchViewController.h"
#import "MEGALogger.h"
#import "MEGARequestDelegate.h"
#import "MEGASdk.h"
#import "MEGASdkManager.h"
#import "MEGATransferDelegate.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

#define MNZ_ANIMATION_TIME 0.35

@interface ShareViewController () <MEGARequestDelegate, MEGATransferDelegate>

@property (nonatomic) UIViewController *privacyVC;
@property (nonatomic) unsigned long pendingAssets;
@property (nonatomic) unsigned long totalAssets;
@property (nonatomic) float progress;

@end

@implementation ShareViewController

#pragma mark - Lifecycle

- (instancetype)init {
    if ([[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] enableSDKlogs];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"logs"] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.shareExt.log"]];
    }
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [[MEGALogger sharedLogger] enableSDKlogs];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if(session) {
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:session delegate:self];
    }

    _privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
    _privacyVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    _privacyVC.navigationItem.rightBarButtonItem.enabled = NO;
    return [super initWithRootViewController:_privacyVC];
}

- (void)viewDidLoad {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    [UIView animateWithDuration:MNZ_ANIMATION_TIME animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - Private

- (void)save {
    [self configureProgressHUD];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    NSExtensionItem *content = self.extensionContext.inputItems[0];
    self.totalAssets = self.pendingAssets = content.attachments.count;
    self.progress = 0;
    for (NSItemProvider *attachment in content.attachments) {
        NSString *typeId;
        
        typeId = (NSString *)kUTTypeImage;
        if ([attachment hasItemConformingToTypeIdentifier:typeId]) {
            [attachment loadItemForTypeIdentifier:typeId options:nil completionHandler:^(id data, NSError *error){
                NSLog(@"Image > %@", (NSURL *)data);
                [self importToSharedSandbox:(NSURL *)data];
            }];
        }
        
        typeId = (NSString *)kUTTypeMovie;
        if ([attachment hasItemConformingToTypeIdentifier:typeId]) {
            [attachment loadItemForTypeIdentifier:typeId options:nil completionHandler:^(id data, NSError *error){
                NSLog(@"Movie > %@", (NSURL *)data);
                [self importToSharedSandbox:(NSURL *)data];
            }];
        }
    }
}

- (void)dismissWithCompletionHandler:(void (^)(void))completion {
    [UIView animateWithDuration:MNZ_ANIMATION_TIME
                     animations:^{
                         self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
}

- (void)importToSharedSandbox:(NSURL *)url {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"Share Extension Storage"] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *path = [url path];
    NSString *tempPath = [storagePath stringByAppendingPathComponent:[path lastPathComponent]];
    [fileManager copyItemAtPath:path toPath:tempPath error:nil];
    [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:tempPath parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:self];

}

- (void)configureProgressHUD {
    [SVProgressHUD setViewForExtension:self.view];

    [SVProgressHUD setFont:[UIFont mnz_SFUIRegularWithSize:12.0f]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingNoTextRadius:18.0];
    [SVProgressHUD setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [SVProgressHUD setForegroundColor:[UIColor mnz_gray666666]];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    self.progress += (transfer.deltaSize.floatValue / transfer.totalBytes.floatValue) / self.totalAssets;
    if (self.progress >= 0.01) {
        NSString *progressCompleted = [NSString stringWithFormat:@"%.f %%", self.progress * 100];
        [SVProgressHUD showProgress:self.progress status:progressCompleted];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [[NSFileManager defaultManager] removeItemAtPath:transfer.path error:nil];
    if (--self.pendingAssets == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        [self dismissWithCompletionHandler:^{
            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        }];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [api fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            self.privacyVC.navigationItem.rightBarButtonItem.enabled = YES;
            break;
        }
            
        default:
            break;
    }
}

@end
