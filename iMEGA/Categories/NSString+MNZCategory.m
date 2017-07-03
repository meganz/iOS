
#import "NSString+MNZCategory.h"

#import "MEGAChatSdk.h"

static NSString* const A = @"[A]";
static NSString* const B = @"[B]";

@implementation NSString (MNZCategory)

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray {
    NSString *countString = [componentsSeparatedByStringArray objectAtIndex:0];
    if ([countString isEqualToString:@"Zero"] || ([countString length] == 0)) {
        countString = @"0";
    }
    
    return countString;
}

+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray {
    NSString *unitString;
    if (componentsSeparatedByStringArray.count == 1) {
        unitString = @"KB";
    } else {
        unitString = [componentsSeparatedByStringArray objectAtIndex:1];
        if ([unitString isEqualToString:@"bytes"] || ([unitString length] == 0)) {
            unitString = @"KB";
        }
    }
    
    return unitString;
}

- (NSString*)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end {
    NSScanner* scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

+ (NSString *)mnz_stringByFiles:(NSInteger)files andFolders:(NSInteger)folders {
    NSString *filesString = [NSString stringWithFormat:@"%ld", (long)files];
    NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)folders];
    
    if (files > 1 && folders > 1) {
        NSString *filesAndFoldersString = AMLocalizedString(@"foldersAndFiles", @"Subtitle shown on folders that gives you information about its content. This case \"[A] = {1+} folders ‚ [B] = {1+} files\"");
        filesAndFoldersString = [filesAndFoldersString stringByReplacingOccurrencesOfString:A withString:foldersString];
        filesAndFoldersString = [filesAndFoldersString stringByReplacingOccurrencesOfString:B withString:filesString];
        return filesAndFoldersString;
    }
    
    if (files > 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFiles", @"Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1+} file\""), (int)files];
    }
    
    if (files > 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"files", @"Subtitle shown on folders that gives you information about its content. This case \"{1+} files\""), (int)files];
    }
    
    if (files == 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFile", @"Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1+} file\""), (int)folders];
    }
    
    if (files == 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFile", @"Subtitle shown on folders that gives you information about its content. This case \"{1} folder • {1} file\""), (int)folders];
    }
    
    if (files == 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFile", @"Subtitle shown on folders that gives you information about its content. This case \"{1} file\""), (int)files];
    }
    
    if (!files && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folders", @"Subtitle shown on folders that gives you information about its content. This case \"{1+} folders\""), (int)folders];
    }
    
    if (!files && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFolder", @"Subtitle shown on folders that gives you information about its content. This case \"{1} folder\""), (int)folders];
    }
    
    return AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
}

+ (NSString *)chatStatusString:(MEGAChatStatus)onlineStatus {
    NSString *onlineStatusString;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            onlineStatusString = AMLocalizedString(@"offline", @"Title of the Offline section");
            break;
            
        case MEGAChatStatusAway:
            onlineStatusString = AMLocalizedString(@"away", nil);
            break;
            
        case MEGAChatStatusOnline:
            onlineStatusString = AMLocalizedString(@"online", nil);
            break;
            
        case MEGAChatStatusBusy:
            onlineStatusString = AMLocalizedString(@"busy", nil);
            break;
            
        default:
            onlineStatusString = nil;
            break;
    }
    
    return onlineStatusString;
}

- (BOOL)mnz_isValidEmail {
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [predicate evaluateWithObject:self];
}

@end
