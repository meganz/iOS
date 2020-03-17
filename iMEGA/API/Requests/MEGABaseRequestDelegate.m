
#import "MEGABaseRequestDelegate.h"

@implementation MEGABaseRequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
#ifndef MNZ_APP_EXTENSION
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
#endif
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
#ifndef MNZ_APP_EXTENSION
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
#endif
}

@end
