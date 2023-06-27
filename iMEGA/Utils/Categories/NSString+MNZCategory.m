
#import "NSString+MNZCategory.h"
#import <AVKit/AVKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import "Helper.h"
#import "NSDate+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import <CoreMedia/CoreMedia.h>

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_NOTIFICATION_EXTENSION
#import "MEGANotifications-Swift.h"
#elif MNZ_WIDGET_EXTENSION
#import "MEGAWidgetExtension-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

static NSString* const A = @"[A]";
static NSString* const B = @"[B]";

@implementation NSString (MNZCategory)

- (BOOL)mnz_isVisualMediaPathExtension {
    
    return [FileExtensionGroupOCWrapper verifyIsImage:self] || [FileExtensionGroupOCWrapper verifyIsVideo:self];
}

- (BOOL)mnz_isMultimediaPathExtension {
    return [FileExtensionGroupOCWrapper verifyIsVideo:self] || [FileExtensionGroupOCWrapper verifyIsAudio:self];
}

- (BOOL)mnz_isTextPathExtension {
    NSArray<NSString *> *supportedExtensions = @[@"txt",
                                                 @"ans",
                                                 @"ascii",
                                                 @"log",
                                                 @"wpd",
                                                 @"json",
                                                 @"md"
    ];
    
    return [supportedExtensions containsObject:self.pathExtension.lowercaseString];
}

- (BOOL)mnz_isWebCodePathExtension {
    NSArray<NSString *> *supportedExtensions = @[@"action",
                                                 @"adp",
                                                 @"ashx",
                                                 @"asmx",
                                                 @"asp",
                                                 @"aspx",
                                                 @"atom",
                                                 @"axd",
                                                 @"bml",
                                                 @"cer",
                                                 @"cfm",
                                                 @"cgi",
                                                 @"css",
                                                 @"dhtml",
                                                 @"do",
                                                 @"dtd",
                                                 @"eml",
                                                 @"htm",
                                                 @"html",
                                                 @"ihtml",
                                                 @"jhtml",
                                                 @"jsonld",
                                                 @"jsp",
                                                 @"jspx",
                                                 @"las",
                                                 @"lasso",
                                                 @"lassoapp",
                                                 @"markdown",
                                                 @"met",
                                                 @"metalink",
                                                 @"mht",
                                                 @"mhtml",
                                                 @"rhtml",
                                                 @"rna",
                                                 @"rnx",
                                                 @"se",
                                                 @"shtml",
                                                 @"stm",
                                                 @"wss",
                                                 @"yaws",
                                                 @"zhtml",
                                                 @"xml",
                                                 @"js",
                                                 @"jar",
                                                 @"java",
                                                 @"class",
                                                 @"php",
                                                 @"php3",
                                                 @"php4",
                                                 @"php5",
                                                 @"phtml",
                                                 @"inc",
                                                 @"pl",
                                                 @"py",
                                                 @"sql",
                                                 @"accdb",
                                                 @"db",
                                                 @"dbf",
                                                 @"mdb",
                                                 @"pdb",
                                                 @"c",
                                                 @"cpp",
                                                 @"h",
                                                 @"cs",
                                                 @"sh",
                                                 @"vb",
                                                 @"swift"
    ];
    
    return [supportedExtensions containsObject:self.pathExtension.lowercaseString];
}

#pragma mark - appData

- (NSString *)mnz_appDataToSaveInPhotosApp {
    return [self stringByAppendingString:@">SaveInPhotosApp"];
}

- (NSString *)mnz_appDataToAttachToChatID:(uint64_t)chatId asVoiceClip:(BOOL)asVoiceClip {
    if (asVoiceClip) {
        return [self stringByAppendingString:[NSString stringWithFormat:@">attachVoiceClipToChatID=%llu", chatId]];
    } else {
        return [self stringByAppendingString:[NSString stringWithFormat:@">attachToChatID=%llu", chatId]];
    }
}

- (NSString *)mnz_appDataToDownloadAttachToMessageID:(uint64_t)messageID {
    return [self stringByAppendingString:[NSString stringWithFormat:@">downloadAttachToMessageID=%llu", messageID]];
   
}

- (NSString *)mnz_appDataToSaveCoordinates:(NSString *)coordinates {
    return (coordinates ? [self stringByAppendingString:[NSString stringWithFormat:@">setCoordinates=%@", coordinates]] : self);
}

- (NSString *)mnz_appDataToLocalIdentifier:(NSString *)localIdentifier {
    return (localIdentifier ? [self stringByAppendingString:[NSString stringWithFormat:@">localIdentifier=%@", localIdentifier]] : self);
}

- (NSString *)mnz_appDataToPath:(NSString *)path {
    return (path ? [self stringByAppendingString:[NSString stringWithFormat:@">path=%@", path]] : self);
}

- (NSString *)mnz_appDataToExportFile {
    return [self stringByAppendingString:@">exportFile"];
}

#pragma mark - Utils

+ (NSString *)mnz_stringWithoutUnitOfComponents:(NSArray *)componentsSeparatedByStringArray {
    NSString *countString = componentsSeparatedByStringArray.firstObject;
    if ([countString isEqualToString:@"Zero"] || ([countString length] == 0)) {
        countString = @"0";
    }
    
    return countString;
}

+ (NSString *)mnz_stringWithoutCountOfComponents:(NSArray *)componentsSeparatedByStringArray {
    NSString *unitString = @"B";
    
    if (componentsSeparatedByStringArray.count > 1) {
        NSString *unitCount = [componentsSeparatedByStringArray objectAtIndex:0];
        unitString = [componentsSeparatedByStringArray objectAtIndex:1];

        if ([unitCount isEqualToString:@"Zero"] ||
            [unitCount isEqualToString:@"0"] ||
            [unitString isEqualToString:@"bytes"] ||
            [unitString length] == 0) {
            unitString = @"B";
        }
    }
    
    return unitString;
}

+ (NSString *)mnz_formatStringFromByteCountFormatter:(NSString *)stringFromByteCount {
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *countString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    
    if (componentsSeparatedByStringArray.count > 1) {
        NSString *unitString = [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray];
        
        countString = [NSString stringWithFormat:@"%@ %@", countString, unitString];
    }
    
    return countString;
}

+ (BOOL)mnz_isByteCountEmpty:(NSString *)stringFromByteCount {
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *countString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    return [countString isEqual: @"0"];
}

- (NSString *_Nullable)mnz_stringBetweenString:(NSString*)start andString:(NSString*)end {
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
    if (files > 0 && folders > 0) {
        NSString *foldersFormat = NSLocalizedString(@"general.format.count.folderAndFile.folder", @"Subtitle shown on folders that shows its folder and file content count. Two strings will be used to make the full sentence to accommodate the multiple plural need. Full sentence examples: 1 folder • 1 file, 2 folders • 2 files, etc");
        NSString *folderCount = [NSString stringWithFormat:foldersFormat, folders];
        
        NSString *filesFormat = NSLocalizedString(@"general.format.count.folderAndFile.file", @"Subtitle shown on folders that shows its folder and file content count. Two strings will be used to make the full sentence to accommodate the multiple plural need. Full sentence examples: 1 folder • 1 file, 2 folders • 2 files, etc");
        NSString *fileCount = [NSString stringWithFormat:filesFormat, files];
        
        return [NSString stringWithFormat:@"%@ %@", folderCount, fileCount];
    }
    
    if (!files && folders > 0) {
        return [NSString stringWithFormat:NSLocalizedString(@"general.format.count.folder", @"Subtitle shown on folders that gives you information about its folder content count. e.g 1 folder, 2 folders"), folders];
    }
    
    if (files > 0 && !folders) {
        return [NSString stringWithFormat:NSLocalizedString(@"general.format.count.file", @"Subtitle shown on folders that gives you information about its file content count. e.g 1 file, 2 files"), files];
    }
    
    return NSLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
}

+ (NSString * _Nullable)chatStatusString:(MEGAChatStatus)onlineStatus {
    NSString *onlineStatusString;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            onlineStatusString = NSLocalizedString(@"offline", @"Title of the Offline section");
            break;
            
        case MEGAChatStatusAway:
            onlineStatusString = NSLocalizedString(@"away", nil);
            break;
            
        case MEGAChatStatusOnline:
            onlineStatusString = NSLocalizedString(@"online", nil);
            break;
            
        case MEGAChatStatusBusy:
            onlineStatusString = NSLocalizedString(@"busy", nil);
            break;
            
        default:
            onlineStatusString = nil;
            break;
    }
    
    return onlineStatusString;
}

+ (NSString *)mnz_stringByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle duration:(NSNumber * _Nullable)duration isGroup:(BOOL)isGroup {
    NSString *endCallReasonString;
    switch (endCallReason) {
        case MEGAChatMessageEndCallReasonByModerator:
        case MEGAChatMessageEndCallReasonEnded: {
            if (isGroup) {
                if (duration != nil && ![duration isEqual: @0]) {
                    endCallReasonString = [[NSLocalizedString(@"[A]Group call ended[/A][C]. Duration: [/C]", @"When an active goup call is ended (with duration)") stringByReplacingOccurrencesOfString:@"[/C]" withString:[NSString mnz_stringFromCallDuration:duration.integerValue]] mnz_removeWebclientFormatters];
                } else {
                    endCallReasonString = NSLocalizedString(@"Group call ended", @"When an active goup call is ended");
                }
            } else {
                endCallReasonString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"callEnded", @"When an active call of user A with user B had ended"), [NSString stringWithFormat:NSLocalizedString(@"duration", @"Displayed after a call had ended, where %@ is the duration of the call (1h, 10seconds, etc)"), [NSString mnz_stringFromCallDuration:duration.integerValue]]];
            }
            break;
        }
            
        case MEGAChatMessageEndCallReasonRejected:
            endCallReasonString = NSLocalizedString(@"callWasRejected", @"When an outgoing call of user A with user B had been rejected by user B");
            break;
            
        case MEGAChatMessageEndCallReasonNoAnswer:
            if (userHandle == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
                endCallReasonString = NSLocalizedString(@"callWasNotAnswered", @"When an active call of user A with user B had not answered");
            } else {
                endCallReasonString = NSLocalizedString(@"missedCall", @"Title of the notification for a missed call");
            }
            
            break;
            
        case MEGAChatMessageEndCallReasonFailed:
            endCallReasonString = NSLocalizedString(@"callFailed", @"When an active call of user A with user B had failed");
            break;
            
        case MEGAChatMessageEndCallReasonCancelled:
            if (userHandle == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
                endCallReasonString = NSLocalizedString(@"callWasCancelled", @"When an active call of user A with user B had cancelled");
            } else {
                endCallReasonString = NSLocalizedString(@"missedCall", @"Title of the notification for a missed call");
            }
            break;
            
        default:
            endCallReasonString = @"[Call] End Call Reason Default";
            break;
    }
    return endCallReasonString;
}

+ (NSString *)mnz_hoursDaysWeeksMonthsOrYearFrom:(NSUInteger)seconds {
    NSUInteger hoursModulo = seconds % secondsInAHour;
    NSUInteger daysModulo = seconds % secondsInADay;
    NSUInteger weeksModulo = seconds % secondsInAWeek;
    NSUInteger monthsModulo = seconds % secondsInAMonth_30;
    NSUInteger yearModulo = seconds % secondsInAYear;
    
    if (yearModulo == 0) {
        NSString *format = NSLocalizedString(@"general.format.retentionPeriod.year", @"The number of years e.g. 1 year, 5 years etc.");
        return [NSString stringWithFormat:format, 1];
    }
    
    if (monthsModulo == 0) {
        NSUInteger months = seconds / secondsInAMonth_30;
        NSString *format = NSLocalizedString(@"general.format.retentionPeriod.month", @"The number of months e.g. 1 month, 5 months etc.");
        return [NSString stringWithFormat:format, months];
    }
    
    if (weeksModulo == 0) {
        NSUInteger weeks = seconds / secondsInAWeek;
        NSString *format = NSLocalizedString(@"general.format.retentionPeriod.week", @"The number of weeks e.g. 1 week, 5 weeks etc.");
        return [NSString stringWithFormat:format, weeks];
    }
    
    if (daysModulo == 0) {
        NSUInteger days = seconds / secondsInADay;
        NSString *format = NSLocalizedString(@"general.format.retentionPeriod.day", @"The number of days e.g. 1 day, 5 days etc.");
        return [NSString stringWithFormat:format, days];
    }
    
    if (hoursModulo == 0) {
        NSUInteger hours = seconds / secondsInAHour;
        NSString *format = NSLocalizedString(@"general.format.retentionPeriod.hour", @"The number of hours e.g. 1 hour, 5 hours etc.");
        return [NSString stringWithFormat:format, hours];
    }
    
    return @"";
}

+ (NSString *)localizedSortOrderType:(MEGASortOrderType)sortOrderType {
    switch (sortOrderType) {
        case MEGASortOrderTypeDefaultDesc:
            return NSLocalizedString(@"nameDescending", @"Sort by option (2/6). This one arranges the files on reverse alphabethical order");
            
        case MEGASortOrderTypeSizeDesc:
            return NSLocalizedString(@"largest", @"Sort by option (3/6). This one order the files by its size, in this case from bigger to smaller size");
            
        case MEGASortOrderTypeSizeAsc:
            return NSLocalizedString(@"smallest", @"Sort by option (4/6). This one order the files by its size, in this case from smaller to bigger size");
            
        case MEGASortOrderTypeModificationDesc:
            return NSLocalizedString(@"newest", @"Sort by option (5/6). This one order the files by its modification date, newer first");
            
        case MEGASortOrderTypeModificationAsc:
            return NSLocalizedString(@"oldest", @"Sort by option (6/6). This one order the files by its modification date, older first");
            
        case MEGASortOrderTypeLabelAsc:
            return NSLocalizedString(@"cloudDrive.sort.label", @"A menu item in the left panel drop down menu to allow sorting by label.");
            
        case MEGASortOrderTypeFavouriteAsc:
            return NSLocalizedString(@"Favourite", @"Context menu item. Allows user to add file/folder to favourites");
            
        default:
            return NSLocalizedString(@"nameAscending", @"Sort by option (1/6). This one orders the files alphabethically");
    }
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

- (NSString *)mnz_removeWhitespacesAndNewlinesFromBothEnds {
    return [self stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

- (BOOL)mnz_containsInvalidChars {
    return [self rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"|*/:<>?\"\\"]].length;
}

- (NSString *)mnz_removeWebclientFormatters {
    NSString *string;
    string = [self stringByReplacingOccurrencesOfString:@"[A]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/A]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[B]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/B]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[S]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/S]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[C]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"[/C]" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"<a href=\"terms\">" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"<a href='terms'>" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"</a>" withString:@""];
    
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

+ (NSString *)mnz_stringFromCallDuration:(NSInteger)duration {
    NSInteger ti = duration;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    if (hours > 0) {
        if (minutes == 0) {
            NSString *format = NSLocalizedString(@"call.duration.hour", nil);
            return [NSString stringWithFormat:format, hours];
        } else {
            NSString *hourFormat = NSLocalizedString(@"call.duration.hourAndMinute.hour", nil);
            NSString *hourString = [NSString stringWithFormat:hourFormat, hours];

            NSString *minuteFormat = NSLocalizedString(@"call.duration.hourAndMinute.minute", nil);
            NSString *minuteString = [NSString stringWithFormat:minuteFormat, minutes];

            return [NSString stringWithFormat:@"%@%@", hourString, minuteString];
        }
    } else if (minutes > 0) {
        NSString *format = NSLocalizedString(@"call.duration.minute", nil);
        return [NSString stringWithFormat:format, minutes];
    } else {
        NSString *format = NSLocalizedString(@"call.duration.second", nil);
        return [NSString stringWithFormat:format, seconds];
    }
}

- (NSString *)SHA256 {
    unsigned int outputLength = CC_SHA256_DIGEST_LENGTH;
    unsigned char output[outputLength];
    
    CC_SHA256(self.UTF8String, (CC_LONG)[self lengthOfBytesUsingEncoding:NSUTF8StringEncoding], output);
    
    NSMutableString* hash = [NSMutableString stringWithCapacity:outputLength * 2];
    for (unsigned int i = 0; i < outputLength; i++) {
        [hash appendFormat:@"%02x", output[i]];
        output[i] = 0;
    }
    
    return hash;
}

- (BOOL)mnz_isDecimalNumber {
    NSCharacterSet *decimalDigitInvertedCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange range = [self rangeOfCharacterFromSet:decimalDigitInvertedCharacterSet];
    
    return (range.location == NSNotFound);
}

- (BOOL)mnz_containsEmoji {
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
                     uc <= 0x1f9ff)
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

- (BOOL)mnz_isPureEmojiString {
    if (self.mnz_isEmpty) {
        return NO;
    }
    
    NSArray *wordsArray = [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *noWhitespacesNorNewlinesString = [wordsArray componentsJoinedByString:@""];
    
    __block BOOL isPureEmojiString = YES;
    
    [noWhitespacesNorNewlinesString enumerateSubstringsInRange:NSMakeRange(0, noWhitespacesNorNewlinesString.length)
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
                     uc <= 0x1f9ff)
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
                     uc <= 0x1f9ff)
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

- (NSString *)mnz_initialForAvatar {
    NSString *trimmedSelf = [self stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedSelf.length == 0) {
        return @"";
    }
    NSUInteger end = [trimmedSelf rangeOfComposedCharacterSequenceAtIndex:0].length;
    return [trimmedSelf substringToIndex:end].uppercaseString;
}

- (NSString * _Nullable)mnz_coordinatesOfPhotoOrVideo {
    
    if ([FileExtensionGroupOCWrapper verifyIsImage:self]) {
        NSURL *fileURL;
        if ([self containsString:@"/tmp/"]) {
            fileURL = [NSURL fileURLWithPath:self];
        } else {
            fileURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:self]];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
            NSData *data = [NSData dataWithContentsOfURL:fileURL];
            if (data) {
                CGImageSourceRef imageData = CGImageSourceCreateWithData((CFDataRef)data, NULL);
                if (imageData) {
                    NSDictionary *metadata = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageData, 0, NULL);
                    
                    CFRelease(imageData);
                    
                    NSDictionary *exifDictionary = [metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
                    if (exifDictionary) {
                        NSNumber *latitude = [exifDictionary objectForKey:@"Latitude"];
                        NSNumber *longitude = [exifDictionary objectForKey:@"Longitude"];
                        if (latitude && longitude) {
                            return [NSString stringWithFormat:@"%@&%@", latitude, longitude];
                        }
                    }
                } else {
                    MEGALogError(@"Create image source with data returns nil");
                }
            } else {
                MEGALogError(@"The data object could not be created");
            }
        } else {
            MEGALogError(@"The file does not exist or its existence could not be determined. File path %@", fileURL);
        }
    }
    
    if ([FileExtensionGroupOCWrapper verifyIsVideo:self]) {
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:self]]];
        for (AVMetadataItem *item in asset.metadata) {
            if ([item.key isEqual:AVMetadataQuickTimeMetadataKeyLocationISO6709]) {
                NSString *locationDescription = item.stringValue;
                if (locationDescription) {
                    NSString *latitude = [locationDescription substringToIndex:8];
                    NSString *longitude = [locationDescription substringWithRange:NSMakeRange(8, 9)];
                    return [NSString stringWithFormat:@"%@&%@", latitude, longitude];
                }
            }
        }
    }
    
    return nil;
}

+ (NSString *)mnz_base64FromBase64URLEncoding:(NSString *)base64URLEncondingString {
    base64URLEncondingString = [base64URLEncondingString stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    base64URLEncondingString = [base64URLEncondingString stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    NSUInteger paddedLength = base64URLEncondingString.length + (4 - (base64URLEncondingString.length % 4));
    NSString *base64FromBase64URLEncoding = [base64URLEncondingString stringByPaddingToLength:paddedLength withString:@"=" startingAtIndex:0];
    
    return base64FromBase64URLEncoding;
}

- (NSString *)mnz_relativeLocalPath {
    return [self stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""];
}

+ (NSString *)mnz_lastGreenStringFromMinutes:(NSInteger)minutes {    
    NSString *lastSeenMessage;
    if (minutes < 65535) {
        NSDate *dateLastSeen = [NSDate dateWithTimeIntervalSinceNow:-minutes * secondsInAMinute];
        NSString *timeString = dateLastSeen.mnz_formattedHourAndMinutes;
        NSString *dateString;
        if ([[NSCalendar currentCalendar] isDateInToday:dateLastSeen]) {
            dateString = NSLocalizedString(@"Today", @"");
        } else if ([[NSCalendar currentCalendar] isDateInYesterday:dateLastSeen]) {
            dateString = NSLocalizedString(@"Yesterday", @"");
        } else {
            dateString = [dateLastSeen formattedDateWithFormat:@"dd MMM"];
        }
        lastSeenMessage = NSLocalizedString(@"Last seen %s", @"Shown when viewing a 1on1 chat (at least for now), if the user is offline.");

        BOOL isRTLLanguage;
        if ([[[[NSBundle mainBundle] bundlePath] pathExtension] isEqualToString:@"appex"]) {
            // App Extensions may not access -[UIApplication sharedApplication]; fall back to checking the bundle's preferred localization character direction
            isRTLLanguage = [NSLocale characterDirectionForLanguage:[[NSBundle mainBundle] preferredLocalizations][0]] == NSLocaleLanguageDirectionRightToLeft;
        } else {
            // Use dynamic call to sharedApplication to workaround compilation error when building against app extensions
            isRTLLanguage = [[UIApplication performSelector:@selector(sharedApplication)] userInterfaceLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft;
        }
        
        if (isRTLLanguage) {
            lastSeenMessage = [lastSeenMessage stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%@ %@", timeString, dateString]];
        } else {
            lastSeenMessage = [lastSeenMessage stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%@ %@", dateString, timeString]];
        }
    } else {
        lastSeenMessage = NSLocalizedString(@"Last seen a long time ago", @"Text to inform the user the 'Last seen' time of a contact is a long time ago (more than 65535 minutes)");
    }
    return lastSeenMessage;
}
    
+ (NSString *)mnz_convertCoordinatesLatitude:(float)latitude longitude:(float)longitude {        
    NSInteger latSeconds = (NSInteger)(latitude * 3600);
    NSInteger latDegrees = latSeconds / 3600;
    latSeconds = ABS(latSeconds % 3600);
    NSInteger latMinutes = latSeconds / 60;
    latSeconds %= 60;
    
    NSInteger longSeconds = (NSInteger)(longitude * 3600);
    NSInteger longDegrees = longSeconds / 3600;
    longSeconds = ABS(longSeconds % 3600);
    NSInteger longMinutes = longSeconds / 60;
    longSeconds %= 60;
    
    NSString* result = [NSString stringWithFormat:@"%td°%td'%td\"%@ %td°%td'%td\"%@",
                        ABS(latDegrees),
                        latMinutes,
                        latSeconds,
                        latDegrees >= 0 ? @"N" : @"S",
                        ABS(longDegrees),
                        longMinutes,
                        longSeconds,
                        longDegrees >= 0 ? @"E" : @"W"];
    
    return result;
}

+ (NSString *)mnz_addedByInRecentActionBucket:(MEGARecentActionBucket *)recentActionBucket {
    NSString *addebByString;
    
    MEGAUser *user = [MEGASdkManager.sharedMEGASdk contactForEmail:recentActionBucket.userEmail];
    NSString *userNameThatMadeTheAction = @"";
    if (user) {
        userNameThatMadeTheAction = user.mnz_firstName ? user.mnz_firstName : @"";
    }
    
    if (recentActionBucket.isUpdate) {
        addebByString = [NSString stringWithFormat:NSLocalizedString(@"home.recent.modifiedByLabel", @"Label that indicates who modified a file into a recents bucket. %1 is a placeholder for a name, eg: Haley"), userNameThatMadeTheAction];
    } else {
        addebByString = [NSString stringWithFormat:NSLocalizedString(@"home.recent.createdByLabel", @"Label that indicates who uploaded a file into a recents bucket. %1 is a placeholder for a name, eg: Haley"), userNameThatMadeTheAction];
    }
    
    return addebByString;
}

#pragma mark - File names and extensions

- (NSString *)mnz_fileNameWithLowercaseExtension {
    NSString *fileName;
    NSString *extension;
    
    NSMutableArray<NSString *> *fileNameComponents = [[self componentsSeparatedByString:@"."] mutableCopy];
    if (fileNameComponents.count > 1) {
        extension = fileNameComponents.lastObject.lowercaseString;
        [fileNameComponents replaceObjectAtIndex:(fileNameComponents.count - 1) withObject:extension];
    }
    fileName = [fileNameComponents componentsJoinedByString:@"."];
    
    return fileName;
}

- (NSString *)mnz_lastExtensionInLowercase {
    NSString *extension;
    NSMutableArray<NSString *> *fileNameComponents = [[self.lastPathComponent componentsSeparatedByString:@"."] mutableCopy];
    if (fileNameComponents.count > 1) {
        extension = fileNameComponents.lastObject.lowercaseString;
    }
    
    return extension;
}

- (NSString *)mnz_sequentialFileNameInParentNode:(MEGANode *)parentNode {
    NSString *nameWithoutExtension = self.stringByDeletingPathExtension;
    NSString *extension = self.pathExtension;
    int index = 0;
    int listSize = 0;
    
    do {
        if (index != 0) {
            nameWithoutExtension = [self.stringByDeletingPathExtension stringByAppendingString:[NSString stringWithFormat:@"_%d", index]];
        }
        
        MEGANodeList *nameNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:parentNode searchString:[nameWithoutExtension stringByAppendingPathExtension:extension]];
        listSize = nameNodeList.size.intValue;
        index++;
    } while (listSize != 0);
    
    return [nameWithoutExtension stringByAppendingPathExtension:extension];
}

- (NSString *)mnz_fileNameWithoutExtension {
    NSString *fileName;
    
    NSMutableArray<NSString *> *fileNameComponents = [[self componentsSeparatedByString:@"."] mutableCopy];
    if (fileNameComponents.count > 1) {
        [fileNameComponents removeLastObject];
    }
    fileName = [fileNameComponents componentsJoinedByString:@"."];
    
    return fileName;
}

- (NSString *)mnz_stringByRemovingInvalidFileCharacters {
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@":/\\"];
    return [[self componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
}

- (CGSize)sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode {
    if (!font) font = [UIFont systemFontOfSize:12];
    NSMutableDictionary *attr = [NSMutableDictionary new];
    attr[NSFontAttributeName] = font;
    if (lineBreakMode != NSLineBreakByWordWrapping) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = lineBreakMode;
        attr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    CGRect rect = [self boundingRectWithSize:size
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attr context:nil];
    return rect.size;
}

@end
