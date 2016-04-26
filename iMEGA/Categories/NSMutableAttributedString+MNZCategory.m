/**
 * @file NSMutableAttributedString+MNZCategory.m
 *
 * (c) 2014-2016 by Mega Limited, Auckland, New Zealand
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

#import <UIKit/UIKit.h>
#import "NSMutableAttributedString+MNZCategory.h"

#import "Helper.h"

@implementation NSMutableAttributedString (MNZCategory)

+ (NSMutableAttributedString *)mnz_darkenSectionTitleInString:(NSString *)string sectionTitle:(NSString *)sectionTitle {
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    
    if ([string rangeOfString:sectionTitle].location != NSNotFound) {
        NSString *stringWithoutSectionTitle;
        [scanner scanUpToString:sectionTitle intoString:&stringWithoutSectionTitle];
        if (stringWithoutSectionTitle != nil) {
            NSMutableAttributedString *stringWithoutSectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:stringWithoutSectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaGray}];
            
            NSMutableAttributedString *sectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaMediumGray}];
            
            [stringWithoutSectionTitleMutableAttributedString appendAttributedString:sectionTitleMutableAttributedString];
            return stringWithoutSectionTitleMutableAttributedString;
        } else {
            if ([scanner scanString:sectionTitle intoString:NULL]) {
                stringWithoutSectionTitle = [string substringFromIndex:scanner.scanLocation];
                
                NSMutableAttributedString *stringWithoutSectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:stringWithoutSectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaGray}];
                
                NSMutableAttributedString *sectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaMediumGray}];
                
                [sectionTitleMutableAttributedString appendAttributedString:stringWithoutSectionTitleMutableAttributedString];
                return sectionTitleMutableAttributedString;
            }
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaGray};
    return [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
}


@end
