#import "ShareViewController.h"

#import <UniformTypeIdentifiers/UTCoreTypes.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"
#import "MEGASdk+MNZCategory.h"

#import "ChatVideoUploadQuality.h"
#import "Helper.h"
#import "LaunchViewController.h"
#import "MEGAChatAttachNodeRequestDelegate.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGALogger.h"
#import "MEGAReachabilityManager.h"
#import "MEGARequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAShare-Swift.h"
#import "MEGATransferDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "ShareAttachment.h"
#import "ShareDestinationTableViewController.h"
#import "MEGAProcessAsset.h"

@import ChatRepo;
@import Firebase;
@import MEGAAppSDKRepo;
@import MEGAL10nObjc;

#define MNZ_ANIMATION_TIME 0.35

@interface ShareViewController () <MEGARequestDelegate, MEGATransferDelegate, MEGAChatRoomDelegate, LTHPasscodeViewControllerDelegate>

@property (nonatomic) NSUInteger pendingAssets;
@property (nonatomic) NSUInteger totalAssets;
@property (nonatomic) NSUInteger unsupportedAssets;
@property (nonatomic) float progress;
@property (nonatomic) NSDate *lastProgressChange;

@property (nonatomic, strong) LaunchViewController *launchVC;
@property (nonatomic, strong) UINavigationController *shareDestinationNavigationVC;

@property (nonatomic) NSString *session;
@property (nonatomic) UIView *privacyView;

@property (nonatomic) BOOL fetchNodesDone;
@property (nonatomic) BOOL passcodePresented;
@property (nonatomic) BOOL passcodeToBePresented;

@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (nonatomic) NSArray<MEGAChatListItem *> *chats;
@property (nonatomic) NSArray<MEGAUser *> *users;
@property (nonatomic) NSMutableSet<NSNumber *> *openedChatIds;
@property (nonatomic, strong) RequestDelegate *logoutDelegate;

@property (strong, nonatomic) MEGANode *parentNode;
@property (nonatomic) NSMutableArray<CancellableTransfer *> *transfers;

@end

@implementation ShareViewController

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [AppEnvironmentConfigurator configAppEnvironment];
        [FIRApp configure];
        [UncaughtExceptionHandler registerHandler];
    }
    return self;
}

- (void)dealloc {
    [self removeShareDestinationView];
    [self removeOpenAppView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if defined(DEBUG) || defined(QA_CONFIG)
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif

    self.sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:MEGAGroupIdentifier];
    if ([self.sharedUserDefaults boolForKey:@"logging"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionLogsFolder] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.shareExt.log"]];
    }
    
    [MEGASdk setLogToConsole:YES];
    
    [self copyDatabasesFromMainApp];
    
    self.fetchNodesDone = NO;
    self.passcodePresented = NO;
    self.passcodeToBePresented = NO;
    
    NSString *languageCode = NSBundle.mainBundle.preferredLocalizations.firstObject;
    [MEGASdk.shared setLanguageCode:languageCode];
    
    // Add observers to get notified when the extension goes to background and comes back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive)
                                                 name:NSExtensionHostWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)
                                                 name:NSExtensionHostDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground)
                                                 name:NSExtensionHostWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                                 name:NSExtensionHostDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
    [AppearanceManager setupAppearance:self.traitCollection];
    [SVProgressHUD setViewForExtension:self.view];
    [[AppFirstLaunchSecurityChecker newChecker] performSecurityCheck];
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (self.session) {
        [self initChatAndStartLogging];
        [self fetchAttachments];
        
        if ([MEGAReachabilityManager isReachable]) {
            [self loginToMEGA];
        } else {
            [self addShareDestinationView];
            [self checkPasscode];
        }
        
        if ([self.sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [MEGASdk.shared useHttpsOnly:YES];
        }
    } else {
        [self openApp];
    }
    
    self.openedChatIds = [NSMutableSet<NSNumber *> new];
    self.lastProgressChange = [NSDate new];
    self.transfers = NSMutableArray.new;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [MEGASdk.shared addMEGARequestDelegate:self.logoutDelegate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGASdk.shared removeMEGARequestDelegateAsync:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self resetSdks];
}

- (void)willResignActive {
    if (self.session) {
        if (self.privacyView == nil) {
            UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
            privacyVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
            privacyVC.view.backgroundColor = UIColor.systemBackgroundColor;
            self.privacyView = privacyVC.view;
            [self.view addSubview:self.privacyView];
        }
    }
}

- (void)didEnterBackground {
    if ([self.presentedViewController isKindOfClass:LTHPasscodeViewController.class]) {
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    self.passcodePresented = NO;
    
    [MEGAChatSdk.shared setBackgroundStatus:YES];
    [MEGAChatSdk.shared saveCurrentState];
    
    if (self.pendingAssets > self.unsupportedAssets) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[NSProcessInfo processInfo] performExpiringActivityWithReason:@"Share Extension activity in progress" usingBlock:^(BOOL expired) {
            if (expired) {
                dispatch_semaphore_signal(semaphore);
                [self resetSdks];
                if (self.pendingAssets > self.unsupportedAssets) {
                    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Share Extension suspended" code:-1 userInfo:nil]];
                } else {
                    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                }
            } else {
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        }];
    }
}

- (void)willEnterForeground {
    [MEGAChatSdk.shared setBackgroundStatus:NO];
    [[MEGAReachabilityManager sharedManager] retryOrReconnect];
}

- (void)didBecomeActive {
    if (self.privacyView) {
        [self.privacyView removeFromSuperview];
        self.privacyView = nil;
    }
    
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (self.session) {
        [self copyDatabasesFromMainApp];
        if (self.openAppNC) {
            [self.openAppNC dismissViewControllerAnimated:YES completion:nil];
            [self initChatAndStartLogging];
            [self fetchAttachments];
        }
        if (!self.fetchNodesDone && [MEGAReachabilityManager isReachable]) {
            [self removeOpenAppView];
            [self loginToMEGA];
        }
        
        [self checkPasscode];
    } else {
        [self openApp];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    MEGALogError(@"Share extension received memory warning");
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar];
    }
}

- (void)resetSdks {
    [MEGAChatSdk.shared saveCurrentState];
    [MEGASdkCleanUp localLogout];
}

#pragma mark - Login and Setup

- (void)initChatAndStartLogging {
    MEGAChatInit chatInit = [MEGAChatSdk.shared initState];
    if (chatInit == MEGAChatInitNotDone) {
        chatInit = [MEGAChatSdk.shared initKarereWithSid:self.session];
        if (chatInit == MEGAChatInitWaitingNewSession || chatInit == MEGAChatInitOfflineSession) {
            [MEGAChatSdk.shared resetClientId];
        }
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere with session failed");
            [MEGAChatSdk.shared logout];
        }
    } else {
        [[MEGAReachabilityManager sharedManager] reconnect];
    }
}

- (void)loginToMEGA {
    self.navigationItem.title = LocalizedString(@"MEGA", @"");
    
    LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
    launchVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.launchVC = launchVC;
    [self.view addSubview:self.launchVC.view];
    
    [MEGASdk.shared fastLoginWithSession:self.session delegate:self];
}

- (UINavigationController *)shareDestinationNavigationVC {
    if (_shareDestinationNavigationVC == nil) {
        UIStoryboard *shareStoryboard = [UIStoryboard storyboardWithName:@"Share" bundle:[NSBundle bundleForClass:ShareDestinationTableViewController.class]];
        _shareDestinationNavigationVC = [shareStoryboard instantiateViewControllerWithIdentifier:@"FilesDestinationNavigationControllerID"];
    }
    
    return _shareDestinationNavigationVC;
}

- (void)addShareDestinationView {
    if (self.shareDestinationNavigationVC.parentViewController == self) {
        return;
    }
    
    [self addChildViewController:self.shareDestinationNavigationVC];
    [self.shareDestinationNavigationVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.shareDestinationNavigationVC.view];
}

- (void)removeShareDestinationView {
    [_shareDestinationNavigationVC setViewControllers:@[]];
    [_shareDestinationNavigationVC removeFromParentViewController];
    [_shareDestinationNavigationVC.view removeFromSuperview];
    _shareDestinationNavigationVC = nil;
}

- (void)checkPasscode {
    if ([LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] setDelegate:self];
        [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        [self presentPasscode];
    }
}

- (void)presentPasscode {
    LTHPasscodeViewController *passcodeVC = [LTHPasscodeViewController sharedUser];
    
    if (!self.passcodePresented && !passcodeVC.isBeingPresented && (passcodeVC.presentingViewController == nil)) {
        [passcodeVC showLockScreenOver:self.view.superview
                         withAnimation:YES
                            withLogout:YES
                        andLogoutTitle:LocalizedString(@"logoutLabel", @"")];
        
        [passcodeVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        passcodeVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:passcodeVC animated:NO completion:nil];
        self.passcodePresented = YES;
    }
    
}

- (void)hideViewWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:MNZ_ANIMATION_TIME
                     animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        [self resetSdks];
        if (completion) {
            completion();
        }
    }];
}

- (void)copyDatabasesFromMainApp {
    NSError *error;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    
    NSURL *groupSupportURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAExtensionGroupSupportFolder];
    if (![fileManager fileExistsAtPath:groupSupportURL.path]) {
        [fileManager createDirectoryAtURL:groupSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSDate *incomingDate = [self newestMegaclientModificationDateForDirectoryAtUrl:groupSupportURL];
    NSDate *extensionDate = [self newestMegaclientModificationDateForDirectoryAtUrl:applicationSupportDirectoryURL];
    
    if ([incomingDate compare:extensionDate] == NSOrderedDescending) {
        NSArray *applicationSupportContent = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectoryURL.path error:&error];
        for (NSString *filename in applicationSupportContent) {
            if ([filename containsString:@"megaclient"] || [filename containsString:@"karere"]) {
                [fileManager mnz_removeItemAtPath:[applicationSupportDirectoryURL.path stringByAppendingPathComponent:filename]];
            }
        }
        
        NSArray *groupSupportPathContent = [fileManager contentsOfDirectoryAtPath:groupSupportURL.path error:&error];
        for (NSString *filename in groupSupportPathContent) {
            if ([filename containsString:@"megaclient_statecache"] || [filename containsString:@"karere"]) {
                if ([fileManager copyItemAtURL:[groupSupportURL URLByAppendingPathComponent:filename] toURL:[applicationSupportDirectoryURL URLByAppendingPathComponent:filename] error:&error]) {
                    MEGALogDebug(@"Copy item at URL: %@ to URL: %@", [groupSupportURL URLByAppendingPathComponent:filename], [applicationSupportDirectoryURL URLByAppendingPathComponent:filename]);
                } else {
                    MEGALogError(@"Copy item at URL failed with error: %@", error);
                }
            }
        }
    }
}

- (NSDate *)newestMegaclientModificationDateForDirectoryAtUrl:(NSURL *)url {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDate *newestDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    NSArray *pathContent = [fileManager contentsOfDirectoryAtPath:url.path error:&error];
    for (NSString *filename in pathContent) {
        if ([filename containsString:@"megaclient"] || [filename containsString:@"karere"]) {
            NSDate *date = [[fileManager attributesOfItemAtPath:[url.path stringByAppendingPathComponent:filename] error:nil] fileModificationDate];
            if ([date compare:newestDate] == NSOrderedDescending) {
                newestDate = date;
            }
        }
    }
    return newestDate;
}

- (RequestDelegate *)logoutDelegate {
    if (_logoutDelegate == nil) {
        __weak __typeof__(self) weakSelf = self;
        _logoutDelegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            switch ([request type]) {
                    
                case MEGARequestTypeLogout: {
                    // if logout (not if localLogout) or session killed in other client
                    BOOL sessionInvalidateInOtherClient = request.paramType == MEGAErrorTypeApiESid;
                    if (request.flag || sessionInvalidateInOtherClient) {
                        [Helper logout];
                        [MEGASdk.shared mnz_setAccountDetails:nil];
                        if (sessionInvalidateInOtherClient) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"loggedOut_alertTitle", @"") message:LocalizedString(@"loggedOutFromAnotherLocation", @"") preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                [weakSelf dismissViewControllerAnimated:YES completion:^{
                                    [weakSelf.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                }];
                            }]];
                            [weakSelf presentViewController:alert animated:YES completion:nil];
                        } else {
                            [weakSelf dismissViewControllerAnimated:YES completion:^{
                                [weakSelf didBecomeActive];
                            }];
                        }
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }];
    }
    
    return _logoutDelegate;
}

#pragma mark - Share Extension

- (void)fetchAttachments {
    if (self.extensionContext.inputItems.count == 0) {
        self.unsupportedAssets = 1;
        [self alertIfNeededAndDismiss];
        
        return;
    }
    
    [ShareAttachment.attachmentsArray removeAllObjects];
    NSExtensionItem *content = self.extensionContext.inputItems.firstObject;
    self.totalAssets = self.pendingAssets = content.attachments.count;
    self.progress = 0;
    self.unsupportedAssets = 0;
    
    // This ordered array is needed because the allKeys properties of the classSupport dictionary are unordered, and the order here is determining
    NSArray<NSString *> *typeIdentifiers = @[UTTypeFileURL.identifier,
                                             UTTypeGIF.identifier,
                                             UTTypeImage.identifier,
                                             UTTypeMovie.identifier,
                                             UTTypeURL.identifier,
                                             UTTypeVCard.identifier,
                                             UTTypePlainText.identifier,
                                             UTTypeData.identifier];
    
    NSDictionary<NSString *, NSArray<Class> *> *classesSupported = @{UTTypeGIF.identifier : @[NSURL.class, NSData.class],
                                                                     UTTypeImage.identifier : @[NSURL.class, UIImage.class, NSData.class],
                                                                     UTTypeMovie.identifier : @[NSURL.class],
                                                                     UTTypeFileURL.identifier : @[NSURL.class],
                                                                     UTTypeURL.identifier : @[NSURL.class],
                                                                     UTTypeVCard.identifier : @[NSData.class],
                                                                     UTTypePlainText.identifier : @[NSString.class],
                                                                     UTTypeData.identifier : @[NSURL.class]};

    for (NSItemProvider *itemProvider in content.attachments) {
        BOOL unsupported = YES;
        
        for (NSString *typeIdentifier in typeIdentifiers) {
            if ([itemProvider hasItemConformingToTypeIdentifier:typeIdentifier]) {
                [itemProvider loadItemForTypeIdentifier:typeIdentifier options:nil completionHandler:^(id data, NSError *error) {
                    if (error) {
                        [self handleError:error];
                    } else {
                        for (Class supportedClass in [classesSupported objectForKey:typeIdentifier]) {
                            if ([[data class] isSubclassOfClass:supportedClass]) {
                                if (supportedClass == NSData.class) {
                                    if ([typeIdentifier isEqualToString:UTTypeGIF.identifier]) {
                                        [ShareAttachment addGIF:(NSData *)data fromItemProvider:itemProvider];
                                    } else if ([typeIdentifier isEqualToString:UTTypeImage.identifier]) {
                                        UIImage *image = [UIImage imageWithData:data];
                                        [ShareAttachment addImage:image fromItemProvider:itemProvider];
                                    } else if ([typeIdentifier isEqualToString:UTTypeVCard.identifier]) {
                                        [ShareAttachment addContact:data];
                                    }
                                    
                                    break;
                                } else if (supportedClass == NSURL.class) {
                                    NSURL *url = (NSURL *)data;
                                    if ([url.scheme isEqualToString:@"file"] && url.hasDirectoryPath) {
                                        [ShareAttachment addFolderURL:url];
                                    } else if (url.isFileURL) {
                                        [ShareAttachment addFileURL:url];
                                    } else {
                                        [ShareAttachment addURL:url];
                                    }
                                    
                                    break;
                                } else if (supportedClass == UIImage.class) {
                                    UIImage *image = (UIImage *)data;
                                    [ShareAttachment addImage:image fromItemProvider:itemProvider];
                                    
                                    break;
                                } else if (supportedClass == NSString.class) {
                                    NSString *text = (NSString *)data;
                                    [ShareAttachment addPlainText:text];
                                    
                                    break;
                                }
                            }
                        }
                    }
                }];
                
                unsupported = NO;
                break;
            }
        }
        
        if (unsupported) {
            self.unsupportedAssets++;
        }
    }
    // If there is no supported asset to process, then the extension is done:
    if (self.pendingAssets == self.unsupportedAssets) {
        [self alertIfNeededAndDismiss];
    }
}

- (void)handleError:(NSError *)error {
    MEGALogError(@"loadItemForTypeIdentifier failed with error %@", error);
    [self oneUnsupportedMore];
}

- (void)performUploadToParentNode:(MEGANode *)parentNode {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    self.transfers = NSMutableArray.new;
    
    for (ShareAttachment *attachment in [[ShareAttachment attachmentsArray] copy]) {
        switch (attachment.type) {
            case ShareAttachmentTypeGIF: {
                [self writeDataAndUpload:attachment toParentNode:parentNode];
                
                break;
            }
                
            case ShareAttachmentTypePNG: {
                UIImage *image = attachment.content;
                [self uploadImage:image withName:attachment.name toParentNode:parentNode isPNG:YES];
                
                break;
            }
                
            case ShareAttachmentTypeImage: {
                UIImage *image = attachment.content;
                [self uploadImage:image withName:attachment.name toParentNode:parentNode isPNG:NO];
                
                break;
            }
                
            case ShareAttachmentTypeFile: {
                NSURL *url = attachment.content;
                if (self.isChatDestination && [FileExtensionGroupOCWrapper verifyIsVideo:url.path]) {
                    NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
                    ChatVideoUploadQuality videoQuality = [[sharedUserDefaults objectForKey:@"ChatVideoQuality"] unsignedIntegerValue];
                    if (videoQuality < ChatVideoUploadQualityOriginal) {
                        NSError *error;
                        NSURL *toUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:url.lastPathComponent]];
                        [NSFileManager.defaultManager copyItemAtURL:url toURL:toUrl error:&error];
                        if (error) {
                            MEGALogError(@"Copy item at URL fails with error %@", error.localizedDescription);
                            // If the file exists in the TMP directory then continue with the process
                            if (error.code != 516) {
                                return;
                            }
                        }
                        MEGAProcessAsset *processAsset = [[MEGAProcessAsset alloc] initToShareThroughChatWithVideoURL:toUrl filePath:^(NSString *filePath) {
                            NSURL *downscaledVideoUrl = [NSURL fileURLWithPath:filePath];
                            if (![attachment.name.pathExtension isEqualToString:@"mp4"]) {
                                attachment.name = [attachment.name stringByDeletingPathExtension];
                                attachment.name = [attachment.name stringByAppendingPathExtension:@"mp4"];
                            }
                            [self uploadData:downscaledVideoUrl withName:attachment.name toParentNode:parentNode isSourceMovable:NO isFile: YES];
                        } error:^(NSError *error) {
                            [SVProgressHUD dismiss];
                        } presenter:self];
                        [processAsset prepare];
                    } else {
                        [self uploadData:url withName:attachment.name toParentNode:parentNode isSourceMovable:NO isFile: YES];
                    }
                } else {
                    [self uploadData:url withName:attachment.name toParentNode:parentNode isSourceMovable:NO isFile:YES];
                }
                break;
            }
                
            case ShareAttachmentTypeFolder: {
                NSURL *url = attachment.content;
                [self uploadData:url withName:attachment.name toParentNode:parentNode isSourceMovable:NO isFile:NO];

                break;
            }
                
            case ShareAttachmentTypeURL: {
                NSURL *url = attachment.content;
                if (self.users || self.chats) {
                    [self performSendMessage:attachment.name];
                } else {
                    [self downloadData:url andUploadToParentNode:parentNode];
                }
                
                break;
            }
                
            case ShareAttachmentTypeContact: {
                [self writeDataAndUpload:attachment toParentNode:parentNode];
                
                break;
            }
                
            case ShareAttachmentTypePlainText: {
                NSString *text = attachment.content;
                if (self.users || self.chats) {
                    [self performSendMessage:text];
                } else {
                    NSString *storagePath = [self shareExtensionStorage];
                    NSString *tempPath = [storagePath stringByAppendingPathComponent:attachment.name];
                    NSError *error;
                    if ([text writeToFile:tempPath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
                        [self smartUploadLocalPath:tempPath parent:parentNode isFile:YES];
                    } else {
                        MEGALogError(@".txt writeToFile failed:\n- At path: %@\n- With error: %@", tempPath, error);
                        [self oneUnsupportedMore];
                    }
                }
            }
        }
    }
}

- (void)performAttachNodeHandle:(uint64_t)nodeHandle {
    MEGAChatAttachNodeRequestDelegate *chatAttachNodeRequestDelegate = [[MEGAChatAttachNodeRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest *request, MEGAChatError *error) {
        if (error.type) {
            [self oneUnsupportedMore];
        } else {
            [self onePendingLess];
        }
    }];
    
    for (MEGAChatListItem *chatListItem in self.chats) {
        self.pendingAssets++;
        [MEGAChatSdk.shared attachNodeToChat:chatListItem.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
    }
    
    for (MEGAUser *user in self.users) {
        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
        if (chatRoom) {
            self.pendingAssets++;
            [MEGAChatSdk.shared attachNodeToChat:chatRoom.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
        } else {
            MEGALogDebug(@"There is not a chat with %@, create the chat and attach", user.email);
            [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                self.pendingAssets++;
                [MEGAChatSdk.shared attachNodeToChat:chatRoom.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
            }];
        }
    }
    
    [self onePendingLess];
}

- (void)performSendMessage:(NSString *)message {
    for (MEGAChatListItem *chatListItem in self.chats) {
        [self sendMessage:message toChat:chatListItem.chatId];
    }
    
    for (MEGAUser *user in self.users) {
        MEGAChatRoom *chatRoom = [MEGAChatSdk.shared chatRoomByUser:user.handle];
        if (chatRoom) {
            [self sendMessage:message toChat:chatRoom.chatId];
        } else {
            MEGALogDebug(@"There is not a chat with %@, create the chat and send message", user.email);
            [MEGAChatSdk.shared mnz_createChatRoomWithUserHandle:user.handle completion:^(MEGAChatRoom * _Nonnull chatRoom) {
                [self sendMessage:message toChat:chatRoom.chatId];
            }];
        }
    }
    
    [self onePendingLess];
}

- (void)sendMessage:(NSString *)message toChat:(uint64_t)chatId {
    if (![self.openedChatIds containsObject:@(chatId)]) {
        [MEGAChatSdk.shared openChatRoom:chatId delegate:self];
        [self.openedChatIds addObject:@(chatId)];
    }
    [MEGAChatSdk.shared sendMessageToChat:chatId message:message];
    self.pendingAssets++;
}

- (void)downloadData:(NSURL *)url andUploadToParentNode:(MEGANode *)parentNode {
    NSURL *urlToDownload = url;
    NSString *urlString = [url absoluteString];
    if ([urlString hasPrefix:@"https://www.dropbox.com"]) {
        // Fix for Dropbox:
        urlString = [urlString stringByReplacingOccurrencesOfString:@"dl=0" withString:@"dl=1"];
        urlToDownload = [NSURL URLWithString:urlString];
    }
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithURL:urlToDownload
                                                                             completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                                                 if (error) {
                                                                                     MEGALogError(@"Share extension error downloading resource at %@: %@", urlToDownload, error);
                                                                                     [self oneUnsupportedMore];
                                                                                 } else {
                                                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                                                         [self uploadData:location withName:response.suggestedFilename toParentNode:parentNode isSourceMovable:YES isFile:YES];
                                                                                     });
                                                                                 }
                                                                             }];
    [downloadTask resume];
}

- (void)uploadImage:(UIImage *)image withName:(NSString *)name toParentNode:(MEGANode *)parentNode isPNG:(BOOL)isPNG {
    NSString *storagePath = [self shareExtensionStorage];
    NSString *tempPath = [storagePath stringByAppendingPathComponent:name];

    if (isPNG ? [UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES] : [UIImageJPEGRepresentation(image, 0.75) writeToFile:tempPath atomically:YES]) {
        [self smartUploadLocalPath:tempPath parent:parentNode isFile:YES];
    } else {
        MEGALogError(@"Image writeToFile failed at path: %@", tempPath);
        [self oneUnsupportedMore];
    }
}

- (void)uploadData:(NSURL *)url withName:(NSString *)name toParentNode:(MEGANode *)parentNode isSourceMovable:(BOOL)sourceMovable isFile:(BOOL)isFile {
    if (url.class == NSURL.class) {
        NSString *storagePath = [self shareExtensionStorage];
        NSString *tempPath = [storagePath stringByAppendingPathComponent:name];
        NSError *error = nil;
        
        [NSFileManager.defaultManager mnz_removeItemAtPath:tempPath];
        
        BOOL success = NO;
        if (sourceMovable) {
            success = [[NSFileManager defaultManager] moveItemAtPath:url.path toPath:tempPath error:&error];
        } else {
            success = [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:tempPath error:&error];
        }
        
        if (success) {
            [self smartUploadLocalPath:tempPath parent:parentNode isFile:isFile];
        } else {
            MEGALogError(@"%@ item failed:\n- At path: %@\n- With error: %@", sourceMovable ? @"Move" : @"Copy", tempPath, error);
            [self oneUnsupportedMore];
        }
    } else {
        MEGALogError(@"Share extension error, %@ object received instead of NSURL or UIImage", url.class);
        [self oneUnsupportedMore];
    }
}

- (void)writeDataAndUpload:(ShareAttachment *)attachment toParentNode:(MEGANode *)parentNode {
    NSString *storagePath = [self shareExtensionStorage];
    NSString *tempPath = [storagePath stringByAppendingPathComponent:attachment.name];
    NSData *data = attachment.content;
    if ([data writeToFile:tempPath atomically:YES]) {
        [self smartUploadLocalPath:tempPath parent:parentNode isFile:YES];
    } else {
        MEGALogError(@"writeToFile failed at path: %@", tempPath);
        [self oneUnsupportedMore];
    }
}

- (NSString *)shareExtensionStorage {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier] URLByAppendingPathComponent:MEGAShareExtensionStorageFolder] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)smartUploadLocalPath:(NSString *)localPath parent:(MEGANode *)parentNode isFile:(BOOL)isFile {
    if (self.users || self.chats) {
        NSString *appData = [[NSString new] mnz_appDataToSaveCoordinates:localPath.mnz_coordinatesOfPhotoOrVideo];
        [MEGASdk.shared startUploadForChatWithLocalPath:localPath parent:parentNode appData:appData isSourceTemporary:YES fileName:nil delegate:self];
    } else {
        [self.transfers addObject:[CancellableTransfer.alloc initWithHandle:MEGAInvalidHandle parentHandle:parentNode.handle fileLinkURL:nil localFileURL:[NSURL fileURLWithPath:localPath] name:nil appData:[NSString.new mnz_appDataToSaveCoordinates:localPath.mnz_coordinatesOfPhotoOrVideo] priority:NO isFile:isFile type:CancellableTransferTypeUpload]];
        [self onePendingLess];
    }
}

- (void)onePendingLess {
    if (--self.pendingAssets == self.unsupportedAssets) {
        [self alertIfNeededAndDismiss];
    }
}

- (void)oneUnsupportedMore {
    if (self.pendingAssets == ++self.unsupportedAssets) {
        [self alertIfNeededAndDismiss];
    }
}

- (void)alertIfNeededAndDismiss {
    [SVProgressHUD dismiss];
    
    for (NSNumber *chatIdNumber in self.openedChatIds) {
        [MEGAChatSdk.shared closeChatRoom:chatIdNumber.unsignedLongLongValue delegate:self];
    }
    
    if (self.unsupportedAssets > 0) {
        NSString *message = LocalizedString(@"shareExtensionUnsupportedAssets", @"Inform user that there were unsupported assets in the share extension.");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (self.pendingAssets == self.unsupportedAssets) {
                [self hideViewWithCompletion:^{
                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                }];
            } else {
                [self processTransfers];
            }
        }]];
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self presentViewController:alertController animated:YES completion:nil];
        }];
    } else {
        [self processTransfers];
    }
}
 
- (void)processTransfers {
    if (self.users || self.chats) {
        unsigned long receiverCount = self.users.count + self.chats.count;
        NSArray<ShareAttachment *> *attachments = [[ShareAttachment attachmentsArray] copy];
        NSString *successMessage = [self successSendToChatMessageWithAttachments:attachments receiverCount:receiverCount];
        [SVProgressHUD showSuccessWithStatus: successMessage];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideViewWithCompletion:^{
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];
        });
    } else {
        [NameCollisionRouterOCWrapper.alloc.init uploadFiles:self.transfers presenter:self type:CancellableTransferTypeUpload];
    }
}

- (void)logout {
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:LocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
    [MEGASdk.shared logout];
}

#pragma mark - BrowserViewControllerDelegate

- (void)uploadToParentNode:(MEGANode *)parentNode {
    if (parentNode) {
        NSExtensionItem *content = self.extensionContext.inputItems.firstObject;
        self.totalAssets = self.pendingAssets = content.attachments.count;
        
        self.parentNode = parentNode;
        [self performUploadToParentNode:parentNode];
    } else {
        __weak __typeof__(self) weakSelf = self;
        [self hideViewWithCompletion:^{
            [weakSelf.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Invalid destination" code:-1 userInfo:nil]];
        }];
    }
}

#pragma mark - SendToViewControllerDelegate

- (void)sendToViewController:(SendToViewController *)viewController toChats:(NSArray<MEGAChatListItem *> *)chats andUsers:(NSArray<MEGAUser *> *)users {
    self.chats = chats;
    self.users = users;
    
    __weak __typeof__(self) weakSelf = self;
    [MyChatFilesFolderNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable myChatFilesFolderNode, NSError * _Nullable error) {
        if (error || myChatFilesFolderNode == nil) {
            MEGALogWarning(@"Coud not load MyChatFiles target folder doe tu error %@", error);
        }
        weakSelf.parentNode = myChatFilesFolderNode;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf performUploadToParentNode:myChatFilesFolderNode];
        });
    }];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
            
        case MEGARequestTypeLogout: {
      
            if (request.paramType != MEGAErrorTypeApiESSL) {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudLogOut"] status:LocalizedString(@"loggingOut", @"String shown when you are logging out of your account.")];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            @autoreleasepool {
                [api fetchNodesWithDelegate:self];
            }
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            self.fetchNodesDone = YES;
            [self.launchVC.view removeFromSuperview];
            [self addShareDestinationView];
            [self checkPasscode];
            break;
        }
            
        case MEGARequestTypeCopy: {
            if (self.users || self.chats) {
                [self performAttachNodeHandle:request.nodeHandle];
            } else {
                [self onePendingLess];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    self.progress += ((float)transfer.deltaSize / (float)transfer.totalBytes) / self.totalAssets;
    if (self.progress >= 0.01 && self.progress < 1.0) {
        NSDate *now = [NSDate new];
        if (!UIAccessibilityIsVoiceOverRunning() || [now timeIntervalSinceDate:self.lastProgressChange] > 2) {
            self.lastProgressChange = now;
            NSString *progressCompleted = [NSString stringWithFormat:@"%.f %%", floor(self.progress * 100)];
            [SVProgressHUD showProgress:self.progress status:progressCompleted];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (error.type) {
        [self oneUnsupportedMore];
        MEGALogError(@"Transfer finished with error: %@", LocalizedString(error.name, @""));
        return;
    }
    
    if (self.users || self.chats) {
        [self performAttachNodeHandle:transfer.nodeHandle];
    } else {
        [self onePendingLess];
    }
}

#pragma mark - MEGAChatRoomDelegate

- (void)onMessageUpdate:(MEGAChatSdk *)api message:(MEGAChatMessage *)message {
    if ([message hasChangedForType:MEGAChatMessageChangeTypeStatus]) {
        if (message.status == MEGAChatMessageStatusServerReceived) {
            [self onePendingLess];
        }
    }
}

#pragma mark - LTHPasscodeViewControllerDelegate

- (void)passcodeWasEnteredSuccessfully {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)maxNumberOfFailedAttemptsReached {
    [self logout];
}

- (void)logoutButtonWasPressed {
    [self logout];
}


@end
