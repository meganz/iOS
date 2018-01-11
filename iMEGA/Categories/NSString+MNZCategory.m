
#import "NSString+MNZCategory.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "MEGAChatSdk.h"

static NSString* const A = @"[A]";
static NSString* const B = @"[B]";

@implementation NSString (MNZCategory)

- (BOOL)mnz_isImageUTI {
    BOOL isImageUTI = NO;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(self.pathExtension.lowercaseString), NULL);
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        isImageUTI = YES;
    }
    if (fileUTI) CFRelease(fileUTI);
    
    return isImageUTI;
}

- (BOOL)mnz_isAudiovisualContentUTI {
    BOOL isAudiovisualContentUTI = NO;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(self.pathExtension.lowercaseString), NULL);
    if (UTTypeConformsTo(fileUTI, kUTTypeAudiovisualContent)) {
        isAudiovisualContentUTI = YES;
    }
    if (fileUTI) CFRelease(fileUTI);
    
    return isAudiovisualContentUTI;
}

- (BOOL)mnz_isImagePathExtension {
    NSSet *imagesExtensionsSet = [[NSSet alloc] initWithObjects:@"gif", @"jpg", @"tif", @"jpeg", @"bmp", @"png", @"nef", @"heic", nil];
    
    return [imagesExtensionsSet containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)mnz_isVideoPathExtension {
    NSSet *videosExtensionsSet = [[NSSet alloc] initWithObjects:@"mp4", @"mov", @"m4v", @"3gp", nil];
    
    return [videosExtensionsSet containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)mnz_isMultimediaPathExtension {
    NSSet *multimediaExtensionsSet = [[NSSet alloc] initWithObjects:@"mp4", @"mov", @"3gp", @"wav", @"m4v", @"m4a", @"mp3", nil];
    
    return [multimediaExtensionsSet containsObject:self.pathExtension.lowercaseString];
}

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
    if (files > 1 && folders > 1) {
        NSString *filesString = [NSString stringWithFormat:@"%ld", (long)files];
        NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)folders];
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

+ (NSString *)mnz_stringByMissedAudioCalls:(NSInteger)missedAudioCalls andMissedVideoCalls:(NSInteger)missedVideoCalls {
    NSString *missedAudioCallsString = [NSString stringWithFormat:@"%ld", (long)missedAudioCalls];
    NSString *missedVideoCallsString = [NSString stringWithFormat:@"%ld", (long)missedVideoCalls];
    NSString *missedString;
    if (missedVideoCalls == 0) {
        if (missedAudioCalls == 1) {
            missedString = AMLocalizedString(@"missedAudioCall", @"Notification text body shown when you have missed one audio call");
        } else { //missedAudioCalls > 1
            missedString = AMLocalizedString(@"missedAudioCalls", @"Notification text body shown when you have missed several audio calls. [A] = {number of missed audio calls}");
            missedString = [missedString stringByReplacingOccurrencesOfString:A withString:missedAudioCallsString];
        }
    } else if (missedVideoCalls == 1) {
        if (missedAudioCalls == 0) {
            missedString = AMLocalizedString(@"missedVideoCall", @"Notification text body shown when you have missed one video call");
        } else if (missedAudioCalls == 1) {
            missedString = AMLocalizedString(@"missedAudioCallAndMissedVideoCall", @"Notification text body shown when you have missed one audio call and one video call");
        } else { //missedAudioCalls > 1
            missedString = AMLocalizedString(@"missedAudioCallsAndMissedVideoCall", @"Notification text body shown when you have missed several audio calls and one video call. [A] = {number of missed audio calls}");
            missedString = [missedString stringByReplacingOccurrencesOfString:A withString:missedAudioCallsString];
        }
    } else { // missedVideoCalls > 1
        if (missedAudioCalls == 0) {
            missedString = AMLocalizedString(@"missedVideoCalls", @"Notification text body shown when you have missed several video calls. [A] = {number of missed video calls}");
            missedString = [missedString stringByReplacingOccurrencesOfString:A withString:missedVideoCallsString];
        } else if (missedAudioCalls == 1) {
            missedString = AMLocalizedString(@"missedAudioCallAndMissedVideoCalls", @"Notification text body shown when you have missed one audio call and several video calls. [A] = {number of missed video calls}");
            missedString = [missedString stringByReplacingOccurrencesOfString:A withString:missedVideoCallsString];
        } else { //missedAudioCalls > 1
            missedString = AMLocalizedString(@"missedAudioCallsAndMissedVideoCalls", @"Notification text body shown when you have missed several audio calls and video calls. [A] = {number of missed audio calls}. [B] = {number of missed video calls}");
            missedString = [missedString stringByReplacingOccurrencesOfString:A withString:missedString];
            missedString = [missedString stringByReplacingOccurrencesOfString:B withString:missedString];            
        }
    }
    
    return missedString;
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

- (BOOL)mnz_isEmpty {
    return ![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
}

- (NSString *)mnz_removeWebclientFormatters {
    NSString *string;
    string = [self stringByReplacingOccurrencesOfString:@"[A]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/A]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[S]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/S]" withString:@""];
    
    return string;
}

+ (NSString *)mnz_stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    } else {
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    }
}

#pragma mark - Emoji utils

- (BOOL)mnz_containsEmoji
{
    __block BOOL containsEmoji = NO;
    
    [self enumerateSubstringsInRange:NSMakeRange(0,
                                                 [self length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop)
     {
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs &&
             hs <= 0xdbff)
         {
             if (substring.length > 1)
             {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc &&
                     uc <= 0x1f9c0)
                 {
                     containsEmoji = YES;
                 }
             }
         }
         else if (substring.length > 1)
         {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3 ||
                 ls == 0xfe0f ||
                 ls == 0xd83c)
             {
                 containsEmoji = YES;
             }
         }
         else
         {
             // non surrogate
             if (0x2100 <= hs &&
                 hs <= 0x27ff)
             {
                 containsEmoji = YES;
             }
             else if (0x2B05 <= hs &&
                      hs <= 0x2b07)
             {
                 containsEmoji = YES;
             }
             else if (0x2934 <= hs &&
                      hs <= 0x2935)
             {
                 containsEmoji = YES;
             }
             else if (0x3297 <= hs &&
                      hs <= 0x3299)
             {
                 containsEmoji = YES;
             }
             else if (hs == 0xa9 ||
                      hs == 0xae ||
                      hs == 0x303d ||
                      hs == 0x3030 ||
                      hs == 0x2b55 ||
                      hs == 0x2b1c ||
                      hs == 0x2b1b ||
                      hs == 0x2b50)
             {
                 containsEmoji = YES;
             }
         }
         
         if (containsEmoji)
         {
             *stop = YES;
         }
     }];
    
    return containsEmoji;
}

- (BOOL)mnz_isPureEmojiString
{
    if (self.length == 0) {
        return NO;
    }
    
    __block BOOL isPureEmojiString = YES;
    
    [self enumerateSubstringsInRange:NSMakeRange(0,
                                                 [self length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop)
     {
         BOOL containsEmoji = NO;
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs &&
             hs <= 0xdbff)
         {
             if (substring.length > 1)
             {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc &&
                     uc <= 0x1f9c0)
                 {
                     containsEmoji = YES;
                 }
             }
         }
         else if (substring.length > 1)
         {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3 ||
                 ls == 0xfe0f ||
                 ls == 0xd83c)
             {
                 containsEmoji = YES;
             }
         }
         else
         {
             // non surrogate
             if (0x2100 <= hs &&
                 hs <= 0x27ff)
             {
                 containsEmoji = YES;
             }
             else if (0x2B05 <= hs &&
                      hs <= 0x2b07)
             {
                 containsEmoji = YES;
             }
             else if (0x2934 <= hs &&
                      hs <= 0x2935)
             {
                 containsEmoji = YES;
             }
             else if (0x3297 <= hs &&
                      hs <= 0x3299)
             {
                 containsEmoji = YES;
             }
             else if (hs == 0xa9 ||
                      hs == 0xae ||
                      hs == 0x303d ||
                      hs == 0x3030 ||
                      hs == 0x2b55 ||
                      hs == 0x2b1c ||
                      hs == 0x2b1b ||
                      hs == 0x2b50)
             {
                 containsEmoji = YES;
             }
         }
         
         if (!containsEmoji)
         {
             isPureEmojiString = NO;
             *stop = YES;
         }
     }];
    
    return isPureEmojiString;
}

- (NSInteger)mnz_emojiCount
{
    __block NSInteger emojiCount = 0;
    
    [self enumerateSubstringsInRange:NSMakeRange(0,
                                                 [self length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *substring,
                                       NSRange substringRange,
                                       NSRange enclosingRange,
                                       BOOL *stop)
     {
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs &&
             hs <= 0xdbff)
         {
             if (substring.length > 1)
             {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc &&
                     uc <= 0x1f9c0)
                 {
                     emojiCount = emojiCount + 1;
                 }
             }
         }
         else if (substring.length > 1)
         {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3 ||
                 ls == 0xfe0f ||
                 ls == 0xd83c)
             {
                 emojiCount = emojiCount + 1;
             }
         }
         else
         {
             // non surrogate
             if (0x2100 <= hs &&
                 hs <= 0x27ff)
             {
                 emojiCount = emojiCount + 1;
             }
             else if (0x2B05 <= hs &&
                      hs <= 0x2b07)
             {
                 emojiCount = emojiCount + 1;
             }
             else if (0x2934 <= hs &&
                      hs <= 0x2935)
             {
                 emojiCount = emojiCount + 1;
             }
             else if (0x3297 <= hs &&
                      hs <= 0x3299)
             {
                 emojiCount = emojiCount + 1;
             }
             else if (hs == 0xa9 ||
                      hs == 0xae ||
                      hs == 0x303d ||
                      hs == 0x3030 ||
                      hs == 0x2b55 ||
                      hs == 0x2b1c ||
                      hs == 0x2b1b ||
                      hs == 0x2b50)
             {
                 emojiCount = emojiCount + 1;
             }
         }
     }];
    
    return emojiCount;
}

@end
