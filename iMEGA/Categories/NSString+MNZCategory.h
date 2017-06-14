
#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface NSString (MNZCategory)

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray;
+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray;

- (NSString*)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end;
+ (NSString*)mnz_stringByFiles:(NSInteger)files andFolders:(NSInteger)folders;

+ (NSString *)chatStatusString:(MEGAChatStatus)onlineStatus;
- (BOOL)mnz_isValidEmail;

@end
