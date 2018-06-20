
#import <Foundation/Foundation.h>

#import "URLType.h"

@interface NSURL (MNZCategory)

- (URLType)mnz_type;
- (NSString *)mnz_MEGAURL;
- (NSString *)mnz_afterSlashesString;

- (void)mnz_showLinkView;

@end
