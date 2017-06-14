
#import "MEGABaseRequestDelegate.h"

@implementation MEGABaseRequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
