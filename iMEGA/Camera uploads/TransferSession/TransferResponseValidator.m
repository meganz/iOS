#import "TransferResponseValidator.h"
#import "NSError+CameraUpload.h"

static NSString * const MEGATransferFailingURLResponseErrorKey = @"nz.mega.transfer.failingURLResponseErrorKey";
static NSString * const MEGATransferFailingURLResponseDataErrorKey = @"nz.mega.transfer.failingURLResponseDataErrorKey";

@interface TransferResponseValidator ()

@property (strong, nonatomic) NSIndexSet *acceptableStatusCodes;

@end

@implementation TransferResponseValidator

- (instancetype)init {
    self = [super init];
    if (self) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

- (BOOL)validateURLResponse:(NSURLResponse *)URLResponse data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    NSError *validationError = nil;
    if (URLResponse && [URLResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)URLResponse;
        if (![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode]) {
            NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];
            mutableUserInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Transfer request failed with status %li %@", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
            mutableUserInfo[NSURLErrorFailingURLErrorKey] = response.URL ?: @"";
            mutableUserInfo[MEGATransferFailingURLResponseErrorKey] = response;
            if (data) {
                mutableUserInfo[MEGATransferFailingURLResponseDataErrorKey] = data;
            }
            
            validationError = [NSError mnz_cameraUploadDataTransferErrorWithUserInfo:[mutableUserInfo copy]];
        }
    }
    
    if (error != NULL) {
        *error = validationError;
    }
    
    return validationError == nil;
}

@end
