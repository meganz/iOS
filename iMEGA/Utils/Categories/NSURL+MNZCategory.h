
#import "URLType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (MNZCategory)

- (void)mnz_presentSafariViewController;

- (NSString *)mnz_MEGAURL;
- (NSURL *)mnz_updatedURLWithCurrentAddress;

/**
 Move a file to a new directory with the ability to rename.

 @param directoryURL the destination directory to move to. A new directory will be created if it is not exist yet.
 @param fileName the new file name.
 @param error the error you pass in to get detail error info when error happens.
 @return YES if succeeded, NO if error happended in file moving.
 */
- (BOOL)mnz_moveToDirectory:(NSURL *)directoryURL renameTo:(NSString *)fileName error:(NSError *__autoreleasing _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
