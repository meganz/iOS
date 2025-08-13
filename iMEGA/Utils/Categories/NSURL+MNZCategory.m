#import "NSURL+MNZCategory.h"

#import <SafariServices/SafariServices.h>

#import "SVProgressHUD.h"
#import "MEGAReachabilityManager.h"
#import "UIApplication+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "MEGA-Swift.h"

#import "LocalizationHelper.h"
@import MEGASDKRepo;

@implementation NSURL (MNZCategory)

- (void)mnz_presentSafariViewController {
    if ([self.scheme.lowercaseString isEqualToString:@"mega"]) {
        MEGALogWarning(@"Link %@ is not supported by the app", self);
        return;
    }
    if (!([self.scheme.lowercaseString isEqualToString:@"http"] || [self.scheme.lowercaseString isEqualToString:@"https"])) {
        [UIApplication.sharedApplication openURL:self options:@{} completionHandler:^(BOOL success) {
            if (success) {
                MEGALogInfo(@"URL opened on other app");
            } else {
                MEGALogInfo(@"URL NOT opened");
                [SVProgressHUD showErrorWithStatus:LocalizedString(@"linkNotValid", @"Message shown when the user clicks on an link that is not valid")];
            }
        }];
        return;
    }
    
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self.absoluteString containsString:RequireTransferSession]) {
            NSUInteger location = [self.absoluteString rangeOfString:RequireTransferSession].location + RequireTransferSession.length;
            NSString *path = [self.absoluteString substringFromIndex:location];
            RequestDelegate *delegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                if (request) {
                    [self presentSafariViewControllerWithLURL:[NSURL URLWithString:request.link]];
                } else {
                    [self presentSafariViewControllerWithLURL:self];
                }
            }];
            
            [MEGASdk.shared getSessionTransferURL:path delegate:delegate];
        } else {
            [self presentSafariViewControllerWithLURL:self];
        }
    }
}

- (void)presentSafariViewControllerWithLURL:(NSURL *)url {
    SFSafariViewController *safariViewController = [SFSafariViewController.alloc initWithURL:url];
    safariViewController.preferredControlTintColor = [UIColor mnz_secondaryTextColor];
    [UIApplication.mnz_visibleViewController presentViewController:safariViewController animated:YES completion:nil];
}

- (NSString *)mnz_MEGAURL {
    NSURLComponents *component = [NSURLComponents.alloc initWithURL:self resolvingAgainstBaseURL:YES];
    component.host = self.domainName;
    component.scheme = @"https";
    return [component.URL absoluteString];
}

- (BOOL)mnz_moveToDirectory:(NSURL *)directoryURL renameTo:(NSString *)fileName error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (![NSFileManager.defaultManager fileExistsAtPath:self.path]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        }
        
        return NO;
    }
    
    NSError *fileError;
    if ([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&fileError]) {
        NSURL *newFileURL = [directoryURL URLByAppendingPathComponent:fileName isDirectory:NO];
        [NSFileManager.defaultManager mnz_removeItemAtPath:newFileURL.path];
        if ([NSFileManager.defaultManager moveItemAtURL:self toURL:newFileURL error:&fileError]) {
            return YES;
        } else {
            MEGALogError(@"%@ error %@ when to copy new file %@", self, fileError, newFileURL);
            if (error != NULL) {
                *error = fileError;
            }
            
            return NO;
        }
    } else {
        MEGALogError(@"%@ error %@ when to create directory %@", self, fileError, directoryURL);
        if (error != NULL) {
            *error = fileError;
        }
        
        return NO;
    }
}

@end
