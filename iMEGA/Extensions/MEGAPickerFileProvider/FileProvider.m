
#import "FileProvider.h"

#import "SAMKeychain.h"

#import "MEGALogger.h"
#import "MEGARequestDelegate.h"
#import "MEGASdk.h"
#import "MEGASdkManager.h"
#import "MEGATransferDelegate.h"

#define kAppKey @"EVtjzb7R"
#define kUserAgent @"MEGAiOS"

@interface FileProvider () <MEGARequestDelegate, MEGATransferDelegate>

@property (nonatomic) MEGANode *oldNode;
@property (nonatomic) NSURL *url;
@property (nonatomic) dispatch_semaphore_t semaphore;

@end

@implementation FileProvider

- (NSFileCoordinator *)fileCoordinator {
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator setPurposeIdentifier:[self providerIdentifier]];
    return fileCoordinator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.fileCoordinator coordinateWritingItemAtURL:self.documentStorageURL options:0 error:nil byAccessor:^(NSURL *newURL) {
            // ensure the documentStorageURL actually exists
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:&error];
        }];
    }
    return self;
}

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler {
    // Should call + writePlaceholderAtURL:withMetadata:error: with the placeholder URL, then call the completion handler with the error if applicable.
    NSString *fileName = [url lastPathComponent];
    
    NSURL *placeholderURL = [NSFileProviderExtension placeholderURLForURL:[self.documentStorageURL URLByAppendingPathComponent:fileName]];
    
    NSUInteger fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil][NSFileSize] unsignedIntegerValue];
    NSDictionary *metadata = @{NSURLFileSizeKey : @(fileSize)};
    [NSFileProviderExtension writePlaceholderAtURL:placeholderURL withMetadata:metadata error:NULL];
    
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)startProvidingItemAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler {
    // Should ensure that the actual file is in the position returned by URLForItemWithIdentifier:, then call the completion handler
    NSError *fileError = nil;
    
    NSData *fileData = [NSData dataWithContentsOfURL:url];
    [fileData writeToURL:url options:0 error:&fileError];
    
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)itemChangedAtURL:(NSURL *)url {
    if ([[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"logging"]) {
        [[MEGALogger sharedLogger] enableSDKlogs];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logsPath = [[[fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.mega.ios"] URLByAppendingPathComponent:@"logs"] path];
        if (![fileManager fileExistsAtPath:logsPath]) {
            [fileManager createDirectoryAtPath:logsPath withIntermediateDirectories:NO attributes:nil error:nil];
        }
        [[MEGALogger sharedLogger] startLoggingToFile:[logsPath stringByAppendingPathComponent:@"MEGAiOS.fileExt.log"]];
    }
    
    [self copyDatabasesFromMainApp];
    
    // Called at some point after the file has changed; the provider may then trigger an upload
    self.url = url;
    self.semaphore = dispatch_semaphore_create(0);
    
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
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)stopProvidingItemAtURL:(NSURL *)url {
    // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
    // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
    
    [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
    [self providePlaceholderAtURL:url completionHandler:^(NSError * __nullable error) {
        // TODO: handle any error, do any necessary cleanup
    }];
}

#pragma mark - Private

- (void)copyDatabasesFromMainApp {
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
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

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    // Currently the old file is not deleted from the cloud.
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            [api fetchNodesWithDelegate:self];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            // Given that the remote file cannot be modified, the new version of the file must be uploaded. Then, it is
            // safe to remove the old file. The file to be uploaded goes to the folder pointed by the parentHandle.
            NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
            NSString *base64Handle = [mySharedDefaults objectForKey:self.url.absoluteString];
            uint64_t handle = [MEGASdk handleForBase64Handle:base64Handle];
            self.oldNode = [api nodeForHandle:handle];
            MEGANode *parent = [api parentNodeForNode:self.oldNode];
            [api startUploadWithLocalPath:self.url.path parent:parent];
            break;
        }
            
        default:
            break;
    }
}

@end
