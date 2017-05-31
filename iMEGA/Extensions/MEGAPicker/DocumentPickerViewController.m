//
//  DocumentPickerViewController.m
//  MEGAPicker
//
//  Created by Javier Trujillo on 29/5/17.
//  Copyright © 2017 MEGA. All rights reserved.
//

#import "DocumentPickerViewController.h"

#import "SVProgressHUD.h"
#import "SAMKeychain.h"

#import "BrowserViewController.h"
#import "MEGANavigationController.h"

#define kUserAgent @"MEGAiOS"
#define kAppKey @"EVtjzb7R"

@interface DocumentPickerViewController ()

@end

@implementation DocumentPickerViewController

-(void)viewDidLoad {
    [SVProgressHUD setViewForExtension:self.view];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    
    [MEGASdkManager setAppKey:kAppKey];
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@", kUserAgent, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    [MEGASdkManager setUserAgent:userAgent];
    
#ifdef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelMax];
#else
    [MEGASdk setLogLevel:MEGALogLevelFatal];
#endif
    
    NSString *session = [SAMKeychain passwordForService:@"MEGA" account:@"sessionV3"];

    if(session) {
        // Common scenario, present the browser.
        [[MEGASdkManager sharedMEGASdk] fastLoginWithSession:session delegate:self];
        
        UIStoryboard *cloudStoryboard = [UIStoryboard storyboardWithName:@"Cloud"
                                                                  bundle:[NSBundle bundleForClass:BrowserViewController.class]];
        MEGANavigationController *navigationController = [cloudStoryboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        
        browserVC.selectedNodesArray = @[];
        [browserVC setBrowserAction:BrowserActionDocumentProvider];
        
        [self addChildViewController:browserVC];
        [browserVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:browserVC.view];
        [browserVC didMoveToParentViewController:self];
        browserVC.browserViewControllerDelegate = self;

    } else {
        // The user either needs to login or logged in before the current version of the MEGA app, so there is
        // no session stored in the shared keychain. In both scenarios, a ViewController from MEGA app is to be pushed.
        // TODO: Empty state to go to MEGA app.
    }
}

- (NSString *)appGroupContainerURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *storagePath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"File Provider Storage"] path];
    if (![fileManager fileExistsAtPath:storagePath]) {
        [fileManager createDirectoryAtPath:storagePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return storagePath;
}

- (void)documentReadyAtPath:(NSString *)path withBase64Handle:(NSString *)base64Handle{
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.mega.ios"];
    // URLByResolvingSymlinksInPath avoids the /private
    NSString *key = [[NSURL fileURLWithPath:path].URLByResolvingSymlinksInPath absoluteString];
    [mySharedDefaults setObject:base64Handle forKey:key];
    
    [self dismissGrantingAccessToURL:[NSURL fileURLWithPath:path]];
}

#pragma mark BrowserViewControllerDelegate

- (void)didSelectNode:(MEGANode *)node {
    NSString *destinationPath = [self appGroupContainerURL];
    NSString *fileName = [node name];
    NSString *documentFilePath = [destinationPath stringByAppendingPathComponent:fileName];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:documentFilePath];
    if (fileExists) {
        // Because MEGA does not support file versioning yet, if the fingerprints are not equal we keep the cloud
        // version of the file deleting the local copy. If the file exists locally and the fingerprints are
        // the same, the local version may be used safely.
        // With file versioning, we may add the local copy to the array of versions before deleting it.
        NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:documentFilePath];
        if ([localFingerprint isEqualToString:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]]) {
            [self documentReadyAtPath:documentFilePath withBase64Handle:[node base64Handle]];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:documentFilePath error:nil];
            [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
        }
    } else {
        [[MEGASdkManager sharedMEGASdk] startDownloadNode:node localPath:documentFilePath delegate:self];
    }
}

#pragma mark MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [[MEGASdkManager sharedMEGASdk] fetchNodes];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            break;
        }
            
        default: {
            break;
        }
    }

}

#pragma mark - MEGATransferDelegate

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    float percentage = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage * 100];
    [SVProgressHUD showProgress:percentage status:percentageCompleted];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
    [SVProgressHUD dismiss];
    [self documentReadyAtPath:transfer.path withBase64Handle:[MEGASdk base64HandleForHandle:transfer.nodeHandle]];
}

@end
