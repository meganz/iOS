
#import <UIKit/UIKit.h>

#import "NSMutableAttributedString+MNZCategory.h"

@implementation NSMutableAttributedString (MNZCategory)

+ (NSMutableAttributedString *)mnz_darkenSectionTitleInString:(NSString *)string sectionTitle:(NSString *)sectionTitle {
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setCharactersToBeSkipped:nil];
    
    if ([string rangeOfString:sectionTitle].location != NSNotFound) {
        NSString *stringWithoutSectionTitle;
        [scanner scanUpToString:sectionTitle intoString:&stringWithoutSectionTitle];
        if (stringWithoutSectionTitle != nil) {
            NSMutableAttributedString *stringWithoutSectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:stringWithoutSectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]}];
            
            NSMutableAttributedString *sectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray777777]}];
            
            [stringWithoutSectionTitleMutableAttributedString appendAttributedString:sectionTitleMutableAttributedString];
            return stringWithoutSectionTitleMutableAttributedString;
        } else {
            if ([scanner scanString:sectionTitle intoString:NULL]) {
                stringWithoutSectionTitle = [string substringFromIndex:scanner.scanLocation];
                
                NSMutableAttributedString *stringWithoutSectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:stringWithoutSectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]}];
                
                NSMutableAttributedString *sectionTitleMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sectionTitle attributes:@{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray777777]}];
                
                [sectionTitleMutableAttributedString appendAttributedString:stringWithoutSectionTitleMutableAttributedString];
                return sectionTitleMutableAttributedString;
            }
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    return [[NSMutableAttributedString alloc] initWithString:string attributes:attributes];
}


@end
