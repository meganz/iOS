
#import "ShareViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "LTHPasscodeViewController.h"
#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "LaunchViewController.h"
#import "LoginRequiredViewController.h"
#import "MEGAChatAttachNodeRequestDelegate.h"
#import "MEGAChatCreateChatGroupRequestDelegate.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGALogger.h"
#import "MEGAReachabilityManager.h"
#import "MEGARequestDelegate.h"
#import "MEGASdk.h"
#import "MEGASdkManager.h"
#import "MEGATransferDelegate.h"
#import "NSString+MNZCategory.h"
#import "ShareAttachment.h"
#import "ShareFilesDestinationTableViewController.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

#define MNZ_ANIMATION_TIME 0.35

@interface ShareViewController () <MEGARequestDelegate, MEGATransferDelegate, MEGAChatRoomDelegate, LTHPasscodeViewControllerDelegate>

@property (nonatomic) UIViewController *browserVC;
@property (nonatomic) NSUInteger pendingAssets;
@property (nonatomic) NSUInteger totalAssets;
@property (nonatomic) NSUInteger unsupportedAssets;
@property (nonatomic) NSUInteger alreadyInDestinationAssets;
@property (nonatomic) float progress;

@property (nonatomic) UINavigationController *loginRequiredNC;
@property (nonatomic) LaunchViewController *launchVC;
@property (nonatomic, getter=isFirstFetchNodesRequestUpdate) BOOL firstFetchNodesRequestUpdate;
@property (nonatomic, getter=isFirstAPI_EAGAIN) BOOL firstAPI_EAGAIN;
@property (nonatomic) NSTimer *timerAPI_EAGAIN;

@property (nonatomic) NSString *session;
@property (nonatomic) UIView *privacyView;

@property (nonatomic) BOOL fetchNodesDone;
@property (nonatomic) BOOL passcodePresented;
@property (nonatomic) BOOL passcodeToBePresented;

@property (nonatomic) NSUserDefaults *sharedUserDefaults;

@property (nonatomic) NSArray<MEGAChatListItem *> *chats;
@property (nonatomic) NSArray<MEGAUser *> *users;

@end

@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    self.sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
    if ([self.sharedUserDefaults boolForKey:@"logging"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"logs"] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.shareExt.log"]];
    }
    
    [self copyDatabasesFromMainApp];
    
    self.fetchNodesDone = NO;
    self.passcodePresented = NO;
    self.passcodeToBePresented = NO;

    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    [self languageCompatibility];
    
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setCatchException:false];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    // Add observers to get notified when the extension goes to background and comes back to foreground:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive)
                                                 name:NSExtensionHostWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                                 name:NSExtensionHostDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground)
                                                 name:NSExtensionHostDidEnterBackgroundNotification
                                               object:nil];

    
    [self setupAppearance];
    [SVProgressHUD setViewForExtension:self.view];
    
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (self.session) {
        [self initChatAndStartLogging];
        [self fetchAttachments];
        
        [[LTHPasscodeViewController sharedUser] setDelegate:self];
        if ([MEGAReachabilityManager isReachable]) {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                self.passcodeToBePresented = YES;
            } else {
                [self loginToMEGA];
            }
        } else {
            if ([LTHPasscodeViewController doesPasscodeExist]) {
                self.passcodeToBePresented = YES;
            } else {
                [self presentFilesDestinationViewController];
            }
        }
        
        if ([self.sharedUserDefaults boolForKey:@"useHttpsOnly"]) {
            [[MEGASdkManager sharedMEGASdk] useHttpsOnly:YES];
        }
    } else {
        [self requireLogin];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self fakeModalPresentation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.passcodeToBePresented) {
        [self presentPasscode];
    }
}

- (void)willResignActive {
    if (self.session) {
        UIViewController *privacyVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"PrivacyViewControllerID"];
        privacyVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
        self.privacyView = privacyVC.view;
        [self.view addSubview:self.privacyView];
    }
}

- (void)didBecomeActive {
    if (self.privacyView) {
        [self.privacyView removeFromSuperview];
        self.privacyView = nil;
    }
    
    self.session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];
    if (self.session) {
        if (self.loginRequiredNC) {
            [self.loginRequiredNC dismissViewControllerAnimated:YES completion:nil];
            [self initChatAndStartLogging];
            [self fetchAttachments];
        }
        if ([LTHPasscodeViewController doesPasscodeExist] && !self.passcodePresented) {
            [self presentPasscode];
        } else {
            if (!self.fetchNodesDone) {
                [self loginToMEGA];
            }
        }
    } else {
        [self requireLogin];
    }
}

- (void)didEnterBackground {
    self.passcodePresented = NO;
}

#pragma mark - Language

- (void)languageCompatibility {
    NSString *languageCode = [self.sharedUserDefaults objectForKey:@"languageCode"];
    if (languageCode) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageCode];
        [[MEGASdkManager sharedMEGASdk] setLanguageCode:languageCode];
    } else {
        NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
        
        if ([Helper isLanguageSupported:currentLanguageID]) {
            [[LocalizationSystem sharedLocalSystem] setLanguage:currentLanguageID];
        } else {
            [self setLanguage:currentLanguageID];
        }
    }
}

- (void)setLanguage:(NSString *)languageID {
    NSDictionary *componentsFromLocaleID = [NSLocale componentsFromLocaleIdentifier:languageID];
    NSString *languageDesignator = [componentsFromLocaleID valueForKey:NSLocaleLanguageCode];
    if ([Helper isLanguageSupported:languageDesignator]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageDesignator];
    } else {
        [self setSystemLanguage];
    }
}

- (void)setSystemLanguage {
    NSDictionary *globalDomain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"NSGlobalDomain"];
    NSArray *languages = [globalDomain objectForKey:@"AppleLanguages"];
    NSString *systemLanguageID = [languages objectAtIndex:0];
    
    if ([Helper isLanguageSupported:systemLanguageID]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:systemLanguageID];
        return;
    }
    
    NSDictionary *componentsFromLocaleID = [NSLocale componentsFromLocaleIdentifier:systemLanguageID];
    NSString *languageDesignator = [componentsFromLocaleID valueForKey:NSLocaleLanguageCode];
    if ([Helper isLanguageSupported:languageDesignator]) {
        [[LocalizationSystem sharedLocalSystem] setLanguage:languageDesignator];
    } else {
        [self setDefaultLanguage];
    }
}

- (void)setDefaultLanguage {
    [[MEGASdkManager sharedMEGASdk] setLanguageCode:@"en"];
    [[LocalizationSystem sharedLocalSystem] setLanguage:@"en"];
}

#pragma mark - Login and Setup

- (void)initChatAndStartLogging {
    if ([self.sharedUserDefaults boolForKey:@"IsChatEnabled"]) {
        if (![MEGASdkManager sharedMEGAChatSdk]) {
            [MEGASdkManager createSharedMEGAChatSdk];
        }
        [[MEGALogger sharedLogger] enableChatlogs];
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:self.session];
        if (chatInit == MEGAChatInitError) {
            MEGALogError(@"Init Karere with session failed");
            [[MEGASdkManager sharedMEGAChatSdk] logout];
        }
    } else {
        [[MEGALogger sharedLogger] enableSDKlogs];
    }
}

- (void)requireLogin {
    // The user either needs to login or logged in before the current version of the MEGA app, so there is
    // no session stored in the shared keychain. In both scenarios, a ViewController from MEGA app is to be pushed.
    if (!self.loginRequiredNC) {
        self.loginRequiredNC = [[UIStoryboard storyboardWithName:@"Share"
                                                          bundle:[NSBundle bundleForClass:[LoginRequiredViewController class]]] instantiateViewControllerWithIdentifier:@"LoginRequiredNavigationControllerID"];
        
        LoginRequiredViewController *loginRequiredVC = self.loginRequiredNC.childViewControllers.firstObject;
        loginRequiredVC.navigationItem.title = @"MEGA";
        loginRequiredVC.cancelBarButtonItem.title = AMLocalizedString(@"cancel", nil);
        loginRequiredVC.cancelCompletion = ^{
            [self.loginRequiredNC dismissViewControllerAnimated:YES completion:^{
                [self dismissWithCompletionHandler:^{
                    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                }];
            }];
        };
        
        [self presentViewController:self.loginRequiredNC animated:YES completion:nil];
    }
}

- (void)setupAppearance {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:17.0f], NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor mnz_redF0373A]];
    [[UINavigationBar appearance] setTranslucent:NO];
    
    //To tint the color of the prompt.
    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTextColor:[UIColor whiteColor]];
    
    [[UISearchBar appearance] setTranslucent:NO];
    [[UISearchBar appearance] setBackgroundColor:UIColor.mnz_grayFCFCFC];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setBackgroundColor:UIColor.mnz_grayEEEEEE];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:13.0f]} forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setTintColor:[UIColor whiteColor]];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIToolbar class]]] setTintColor:[UIColor mnz_redF0373A]];
    
    [[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"backArrow"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"backArrow"]];
    
    [[UITextField appearance] setTintColor:UIColor.mnz_green00BFA5];
        
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UIAlertController class]]] setTintColor:[UIColor mnz_redF0373A]];
    
    [[UIProgressView appearance] setTintColor:[UIColor mnz_redF0373A]];
    
    [self configureProgressHUD];
}

- (void)configureProgressHUD {
    [SVProgressHUD setViewForExtension:self.view];
    
    [SVProgressHUD setFont:[UIFont mnz_SFUIRegularWithSize:12.0f]];
    [SVProgressHUD setRingThickness:2.0];
    [SVProgressHUD setRingNoTextRadius:18.0];
    [SVProgressHUD setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [SVProgressHUD setForegroundColor:[UIColor mnz_gray666666]];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleCustom];
    [SVProgressHUD setHapticsEnabled:YES];
    
    [SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hudSuccess"]];
    [SVProgressHUD setErrorImage:[UIImage imageNamed:@"hudError"]];
}

- (IBAction)openMegaTouchUpInside:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mega://#loginrequired"]];
}

- (void)loginToMEGA {
    self.navigationItem.title = @"MEGA";
    
    LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:[NSBundle bundleForClass:[LaunchViewController class]]] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
    launchVC.view.frame = CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height);
    self.launchVC = launchVC;
    [self.view addSubview:self.launchVC.view];
    
    [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:self.session delegate:self];
}

- (void)presentFilesDestinationViewController {
    UIStoryboard *shareStoryboard = [UIStoryboard storyboardWithName:@"Share" bundle:[NSBundle bundleForClass:ShareFilesDestinationTableViewController.class]];
    UINavigationController *navigationController = [shareStoryboard instantiateViewControllerWithIdentifier:@"FilesDestinationNavigationControllerID"];
    
    [self addChildViewController:navigationController];
    [navigationController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:navigationController.view];
}

- (void)presentPasscode {
    if (!self.passcodePresented) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
            [[LTHPasscodeViewController sharedUser] setMaxNumberOfAllowedFailedAttempts:10];
        }
        
        LTHPasscodeViewController *passcodeVC = [LTHPasscodeViewController sharedUser];
        [passcodeVC showLockScreenOver:self.view.superview
                         withAnimation:YES
                            withLogout:YES
                        andLogoutTitle:AMLocalizedString(@"logoutLabel", nil)];
        
        [passcodeVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self presentViewController:passcodeVC animated:NO completion:nil];
        self.passcodePresented = YES;
        self.passcodeToBePresented = NO;
    }
}

- (void)startTimerAPI_EAGAIN {
    self.timerAPI_EAGAIN = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showServersTooBusy) userInfo:nil repeats:NO];
}

- (void)invalidateTimerAPI_EAGAIN {
    [self.timerAPI_EAGAIN invalidate];
    
    self.launchVC.label.text = @"";
}

- (void)showServersTooBusy {
    self.launchVC.label.text = AMLocalizedString(@"takingLongerThanExpected", @"Message shown when you open the app and when it is logging in, you don't receive server response, that means that it may take some time until you log in");
}

- (void)fakeModalPresentation {
    self.view.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height);
    [UIView animateWithDuration:MNZ_ANIMATION_TIME animations:^{
        self.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismissWithCompletionHandler:(void (^)(void))completion {
    [[ShareAttachment attachmentsArray] removeAllObjects];
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

- (void)copyDatabasesFromMainApp {
    NSError *error;
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSURL *applicationSupportDirectoryURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        MEGALogError(@"Failed to locate/create NSApplicationSupportDirectory with error: %@", error);
    }
    
    NSURL *groupSupportURL = [[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"GroupSupport"];
    if (![fileManager fileExistsAtPath:groupSupportURL.path]) {
        [fileManager createDirectoryAtURL:groupSupportURL withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSDate *incomingDate = [self newestMegaclientModificationDateForDirectoryAtUrl:groupSupportURL];
    NSDate *extensionDate = [self newestMegaclientModificationDateForDirectoryAtUrl:applicationSupportDirectoryURL];
    
    if ([incomingDate compare:extensionDate] == NSOrderedDescending) {
        NSArray *applicationSupportContent = [fileManager contentsOfDirectoryAtPath:applicationSupportDirectoryURL.path error:&error];
        for (NSString *filename in applicationSupportContent) {
            if ([filename containsString:@"megaclient"]) {
                if(![fileManager removeItemAtPath:[applicationSupportDirectoryURL.path stringByAppendingPathComponent:filename] error:&error]) {
                    MEGALogError(@"Remove item at path failed with error: %@", error);
                }
            }
        }
        
        NSArray *groupSupportPathContent = [fileManager contentsOfDirectoryAtPath:groupSupportURL.path error:&error];
        for (NSString *filename in groupSupportPathContent) {
            if ([filename containsString:@"megaclient"]) {
                if (![fileManager copyItemAtURL:[groupSupportURL URLByAppendingPathComponent:filename] toURL:[applicationSupportDirectoryURL URLByAppendingPathComponent:filename] error:&error]) {
                    MEGALogError(@"Copy item at path failed with error: %@", error);
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
        if ([filename containsString:@"megaclient"]) {
            NSDate *date = [[fileManager attributesOfItemAtPath:[url.path stringByAppendingPathComponent:filename] error:nil] fileModificationDate];
            if ([date compare:newestDate] == NSOrderedDescending) {
                newestDate = date;
            }
        }
    }
    return newestDate;
}

void uncaughtExceptionHandler(NSException *exception) {
    MEGALogError(@"Exception name: %@\nreason: %@\nuser info: %@\n", exception.name, exception.reason, exception.userInfo);
    MEGALogError(@"Stack trace: %@", [exception callStackSymbols]);
}

#pragma mark - Share Extension

- (void)fetchAttachments {
    if (self.extensionContext.inputItems.count == 0) {
        self.unsupportedAssets = 1;
        [self alertIfNeededAndDismiss];
        
        return;
    }
    
    NSExtensionItem *content = self.extensionContext.inputItems[0];
    self.totalAssets = self.pendingAssets = content.attachments.count;
    self.progress = 0;
    self.unsupportedAssets = self.alreadyInDestinationAssets = 0;

    for (NSItemProvider *itemProvider in content.attachments) {
        if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    if ([data class] == UIImage.class) {
                        UIImage *image = (UIImage *)data;
                        [ShareAttachment addImage:image fromItemProvider:itemProvider];
                    } else if ([[data class] isSubclassOfClass:NSData.class]) {
                        UIImage *image = [UIImage imageWithData:data];
                        [ShareAttachment addImage:image fromItemProvider:itemProvider];
                    } else {
                        NSURL *url = (NSURL *)data;
                        [ShareAttachment addFileURL:url];
                    }
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    NSURL *url = (NSURL *)data;
                    [ShareAttachment addFileURL:url];
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
            // This type includes kUTTypeText, so kUTTypeText is omitted
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    NSURL *url = (NSURL *)data;
                    [ShareAttachment addFileURL:url];
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    NSURL *url = (NSURL *)data;
                    [ShareAttachment addURL:url];
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVCard]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeVCard options:nil completionHandler:^(NSData *vCardData, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    [ShareAttachment addContact:vCardData];
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePlainText]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePlainText options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    NSString *text = (NSString *)data;
                    [ShareAttachment addPlainText:text];
                }
            }];
        } else if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeData]) {
            [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeData options:nil completionHandler:^(id data, NSError *error) {
                if (error) {
                    [self handleError:error];
                } else {
                    NSURL *url = (NSURL *)data;
                    [ShareAttachment addFileURL:url];
                }
            }];
        } else {
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
    
    for (ShareAttachment *attachment in [ShareAttachment attachmentsArray]) {
        switch (attachment.type) {
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
                [self uploadData:url withName:attachment.name toParentNode:parentNode isSourceMovable:NO];
                
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
                NSString *storagePath = [self shareExtensionStorage];
                NSString *tempPath = [storagePath stringByAppendingPathComponent:attachment.name];
                NSData *vCardData = attachment.content;
                if ([vCardData writeToFile:tempPath atomically:YES]) {
                    [self smartUploadLocalPath:tempPath parent:parentNode];
                } else {
                    MEGALogError(@".vcf writeToFile failed at path: %@", tempPath);
                    [self oneUnsupportedMore];
                }
                
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
                        [self smartUploadLocalPath:tempPath parent:parentNode];
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
    MEGAChatAttachNodeRequestDelegate *chatAttachNodeRequestDelegate = [[MEGAChatAttachNodeRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type) {
            [self oneUnsupportedMore];
        } else {
            [self onePendingLess];
        }
    }];
    
    for (MEGAChatListItem *chatListItem in self.chats) {
        [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatListItem.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
    }
    
    for (MEGAUser *user in self.users) {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
        if (chatRoom) {
            [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatRoom.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
        } else {
            MEGALogDebug(@"There is not a chat with %@, create the chat and attach", user.email);
            MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
            [peerList addPeerWithHandle:user.handle privilege:MEGAChatRoomPrivilegeStandard];
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                [[MEGASdkManager sharedMEGAChatSdk] attachNodeToChat:chatRoom.chatId node:nodeHandle delegate:chatAttachNodeRequestDelegate];
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
        }
    }
}

- (void)performSendMessage:(NSString *)message {
    for (MEGAChatListItem *chatListItem in self.chats) {
        [self sendMessage:message toChat:chatListItem.chatId];
    }
    
    for (MEGAUser *user in self.users) {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomByUser:user.handle];
        if (chatRoom) {
            [self sendMessage:message toChat:chatRoom.chatId];
        } else {
            MEGALogDebug(@"There is not a chat with %@, create the chat and send message", user.email);
            MEGAChatPeerList *peerList = [[MEGAChatPeerList alloc] init];
            [peerList addPeerWithHandle:user.handle privilege:MEGAChatRoomPrivilegeStandard];
            MEGAChatCreateChatGroupRequestDelegate *createChatGroupRequestDelegate = [[MEGAChatCreateChatGroupRequestDelegate alloc] initWithCompletion:^(MEGAChatRoom *chatRoom) {
                [self sendMessage:message toChat:chatRoom.chatId];
            }];
            [[MEGASdkManager sharedMEGAChatSdk] createChatGroup:NO peers:peerList delegate:createChatGroupRequestDelegate];
        }
    }
    
    [self onePendingLess];
}

- (void)sendMessage:(NSString *)message toChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] openChatRoom:chatId delegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] sendMessageToChat:chatId message:message];
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
                                                                                     [self uploadData:location withName:response.suggestedFilename toParentNode:parentNode isSourceMovable:YES];
                                                                                 }
                                                                             }];
    [downloadTask resume];
}

- (void)uploadImage:(UIImage *)image withName:(NSString *)name toParentNode:(MEGANode *)parentNode isPNG:(BOOL)isPNG {
    NSString *storagePath = [self shareExtensionStorage];
    NSString *tempPath = [storagePath stringByAppendingPathComponent:name];

    if (isPNG ? [UIImagePNGRepresentation(image) writeToFile:tempPath atomically:YES] : [UIImageJPEGRepresentation(image, 0.75) writeToFile:tempPath atomically:YES]) {
        [self smartUploadLocalPath:tempPath parent:parentNode];
    } else {
        MEGALogError(@"Image writeToFile failed at path: %@", tempPath);
        [self oneUnsupportedMore];
    }
}

- (void)uploadData:(NSURL *)url withName:(NSString *)name toParentNode:(MEGANode *)parentNode isSourceMovable:(BOOL)sourceMovable {
    if (url.class == NSURL.class) {
        NSString *storagePath = [self shareExtensionStorage];
        NSString *tempPath = [storagePath stringByAppendingPathComponent:name];
        NSError *error = nil;
        
        BOOL success = NO;
        if (sourceMovable) {
            success = [[NSFileManager defaultManager] moveItemAtPath:url.path toPath:tempPath error:&error];
        } else {
            success = [[NSFileManager defaultManager] copyItemAtPath:url.path toPath:tempPath error:&error];
        }
        
        if (success) {
            [self smartUploadLocalPath:tempPath parent:parentNode];
        } else {
            MEGALogError(@"%@ item failed:\n- At path: %@\n- With error: %@", sourceMovable ? @"Move" : @"Copy", tempPath, error);
            [self oneUnsupportedMore];
        }
    } else {
        MEGALogError(@"Share extension error, %@ object received instead of NSURL or UIImage", url.class);
        [self oneUnsupportedMore];
    }
}

- (NSString *)shareExtensionStorage {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"Share Extension Storage"] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)smartUploadLocalPath:(NSString *)localPath parent:(MEGANode *)parentNode {
    NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:localPath];
    MEGANode *remoteNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerprint parent:parentNode];
    if (remoteNode) {
        if (remoteNode.parentHandle == parentNode.handle) {
            // The file is already in the folder, nothing to do.
            if (self.users || self.chats) {
                [self performAttachNodeHandle:remoteNode.handle];
            } else {
                self.alreadyInDestinationAssets++;
                [self onePendingLess];
            }
        } else {
            if ([remoteNode.name isEqualToString:localPath.lastPathComponent]) {
                // The file is already in MEGA, in other folder, has to be copied to this folder.
                [[MEGASdkManager sharedMEGASdk] copyNode:remoteNode newParent:parentNode delegate:self];
            } else {
                // The file is already in MEGA, in other folder with different name, has to be copied to this folder and renamed.
                [[MEGASdkManager sharedMEGASdk] copyNode:remoteNode newParent:parentNode newName:localPath.lastPathComponent delegate:self];
            }
        }
        [[NSFileManager defaultManager] removeItemAtPath:localPath error:nil];
    } else {
        // The file is not in MEGA.
        NSString *appData = [[NSString new] mnz_appDataToSaveCoordinates:localPath.mnz_coordinatesOfPhotoOrVideo];
        [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localPath parent:parentNode appData:appData isSourceTemporary:YES delegate:self];
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
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    if (self.unsupportedAssets > 0 || self.alreadyInDestinationAssets > 0) {
        NSString *message;
        if (self.unsupportedAssets > 0) {
            message = AMLocalizedString(@"shareExtensionUnsupportedAssets", @"Inform user that there were unsupported assets in the share extension.");
        } else {
            message = [NSString stringWithFormat:AMLocalizedString(@"filesAlreadyExistMessage", @"Message shown when you try to upload some photos or/and videos that are already uploaded in the current folder"), self.alreadyInDestinationAssets];
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self dismissWithCompletionHandler:^{
                [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
            }];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self dismissWithCompletionHandler:^{
            [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        }];
    }
}

#pragma mark - BrowserViewControllerDelegate

- (void)uploadToParentNode:(MEGANode *)parentNode {
    if (parentNode) {
        [self performUploadToParentNode:parentNode];
    } else {
        [self dismissWithCompletionHandler:^{
            [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"Invalid destination" code:-1 userInfo:nil]];
        }];
    }
}

#pragma mark - SendToViewControllerDelegate

- (void)sendToChats:(NSArray<MEGAChatListItem *> *)chats andUsers:(NSArray<MEGAUser *> *)users {
    self.chats = chats;
    self.users = users;
    
    MEGANode *myChatFilesNode = [[MEGASdkManager sharedMEGASdk] nodeForPath:@"/My chat files"];
    if (myChatFilesNode) {
        [self performUploadToParentNode:myChatFilesNode];
    } else {
        MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGANode *myChatFilesNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            [self performUploadToParentNode:myChatFilesNode];
        }];
        [[MEGASdkManager sharedMEGASdk] createFolderWithName:@"My chat files" parent:[[MEGASdkManager sharedMEGASdk] rootNode] delegate:createFolderRequestDelegate];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            self.launchVC.activityIndicatorView.hidden = NO;
            [self.launchVC.activityIndicatorView startAnimating];
            
            self.firstAPI_EAGAIN = YES;
            self.firstFetchNodesRequestUpdate = YES;
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeFetchNodes) {
        [self invalidateTimerAPI_EAGAIN];
        
        float progress = (request.transferredBytes.floatValue / request.totalBytes.floatValue);
        
        if (self.isFirstFetchNodesRequestUpdate) {
            [self.launchVC.activityIndicatorView stopAnimating];
            self.launchVC.activityIndicatorView.hidden = YES;
            
            [self.launchVC.logoImageView.layer addSublayer:self.launchVC.circularShapeLayer];
            self.launchVC.circularShapeLayer.strokeStart = 0.0f;
        }
        
        if (progress > 0 && progress <= 1.0) {
            self.launchVC.circularShapeLayer.strokeEnd = progress;
        }
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [self invalidateTimerAPI_EAGAIN];
            
            [api fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [self invalidateTimerAPI_EAGAIN];
            
            self.fetchNodesDone = YES;
            [self.launchVC.view removeFromSuperview];
            [[MEGASdkManager sharedMEGAChatSdk] connectInBackground];
            [self presentFilesDestinationViewController];
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

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if (self.isFirstAPI_EAGAIN) {
                [self startTimerAPI_EAGAIN];
                self.firstAPI_EAGAIN = NO;
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    self.progress += (transfer.deltaSize.floatValue / transfer.totalBytes.floatValue) / self.totalAssets;
    if (self.progress >= 0.01 && self.progress < 1.0) {
        NSString *progressCompleted = [NSString stringWithFormat:@"%.f %%", floor(self.progress * 100)];
        [SVProgressHUD showProgress:self.progress status:progressCompleted];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
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
    [self dismissViewControllerAnimated:YES completion:^{
        self.passcodePresented = YES;
        if ([MEGAReachabilityManager isReachable]) {
            if (!self.fetchNodesDone) {
                [self loginToMEGA];
            }
        } else {
            [self presentFilesDestinationViewController];
        }
    }];
}

- (void)maxNumberOfFailedAttemptsReached {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIsEraseAllLocalDataEnabled]) {
        [[MEGASdkManager sharedMEGASdk] logout];
    }
}

- (void)logoutButtonWasPressed {
    [[MEGASdkManager sharedMEGASdk] logout];
}

@end
