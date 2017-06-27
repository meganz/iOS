
#import "ShareViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "BrowserViewController.h"
#import "LaunchViewController.h"
#import "MEGALogger.h"
#import "MEGANavigationController.h"
#import "MEGARequestDelegate.h"
#import "MEGASdk.h"
#import "MEGASdkManager.h"
#import "MEGATransferDelegate.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

#define MNZ_ANIMATION_TIME 0.35

@interface ShareViewController () <MEGARequestDelegate, MEGATransferDelegate>

@property (nonatomic) UIViewController *browserVC;
@property (nonatomic) unsigned long pendingAssets;
@property (nonatomic) unsigned long totalAssets;
@property (nonatomic) unsigned long unsupportedAssets;
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

    return [super init];
}

- (void)viewDidLoad {
    UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:[NSBundle bundleForClass:BrowserViewController.class]];
    MEGANavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.browserAction = BrowserActionShareExtension;
    browserVC.browserViewControllerDelegate = self;
    
    [self addChildViewController:navigationController];
    [navigationController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:navigationController.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    [UIView animateWithDuration:MNZ_ANIMATION_TIME animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - Private

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

- (void)uploadData:(NSURL *)url toParentNode:parentNode {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"Share Extension Storage"] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    NSString *path = [url path];
    NSString *tempPath = [storagePath stringByAppendingPathComponent:[path lastPathComponent]];
    [fileManager copyItemAtPath:path toPath:tempPath error:nil];
    [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:tempPath parent:parentNode delegate:self];

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

#pragma mark - BrowserViewControllerDelegate

- (void)uploadToParentNode:(MEGANode *)parentNode {
    if (parentNode) {
        // The user tapped "Upload":
        [self configureProgressHUD];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
        
        NSExtensionItem *content = self.extensionContext.inputItems[0];
        self.totalAssets = self.pendingAssets = content.attachments.count;
        self.progress = 0;
        self.unsupportedAssets = 0;
        for (NSItemProvider *attachment in content.attachments) {
            if ([attachment hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                [attachment loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id data, NSError *error){
                    NSLog(@"Image > %@", (NSURL *)data);
                    [self uploadData:(NSURL *)data toParentNode:parentNode];
                }];
            } else if ([attachment hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                [attachment loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id data, NSError *error){
                    NSLog(@"Movie > %@", (NSURL *)data);
                    [self uploadData:(NSURL *)data toParentNode:parentNode];
                }];
            } else if ([attachment hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
                // This type includes kUTTypeText, so kUTTypeText it's omitted
                [attachment loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(id data, NSError *error){
                    NSLog(@"File > %@", (NSURL *)data);
                    [self uploadData:(NSURL *)data toParentNode:parentNode];
                }];
            } else {
                self.unsupportedAssets++;
            }
        }
        // If there is no supported asset to process, then the extension is done:
        if (self.pendingAssets == self.unsupportedAssets) {
            [self dismissWithCompletionHandler:^{
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];
        }
    } else {
        // The user tapped "Cancel":
        [self dismissWithCompletionHandler:^{
            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        }];
    }
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
    if (--self.pendingAssets == self.unsupportedAssets) {
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
            break;
        }
            
        default:
            break;
    }
}

@end
