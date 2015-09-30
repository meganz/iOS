/**
 * @file MNZCategory.m
 * @brief Get string between two other strings
 *
 * (c) 2014-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "NSString+MNZCategory.h"

static NSString* const A = @"[A]";
static NSString* const B = @"[B]";

@implementation NSString (MNZCategory)

- (NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end {
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

- (NSString *)stringByFiles:(NSInteger)files andFolders:(NSInteger)folders {
    NSString *filesString = [NSString stringWithFormat:@"%ld", files];
    NSString *foldersString = [NSString stringWithFormat:@"%ld", folders];
    
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


@end
