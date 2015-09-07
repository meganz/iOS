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
    if (files > 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFiles", @"Folders, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFiles", @"Folder, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"files", @"Files"), (int)files];
    }
    
    if (files == 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFile", @"Folders, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFile", @"Folder, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFile", @"File"), (int)files];
    }
    
    if (!files && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folders", @"Folders"), (int)folders];
    }
    
    if (!files && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFolder", @"Folder"), (int)folders];
    }
    
    return AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
}


@end
