
#import "URLType.h"

@interface NSURL (MNZCategory)

- (void)mnz_presentSafariViewController;

- (URLType)mnz_type;
- (NSString *)mnz_MEGAURL;
- (NSString *)mnz_afterSlashesString;
- (NSURL *)mnz_updatedURLWithCurrentAddress;

@end
