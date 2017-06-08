#import "MEGAOpenMessageHeaderView.h"

@interface MEGAOpenMessageHeaderView ()

@end

@implementation MEGAOpenMessageHeaderView

+ (UINib *)nib {
    return [UINib nibWithNibName:@"MEGAOpenMessageHeaderView" bundle:nil];
}

+ (NSString *)headerReuseIdentifier {
    return @"MEGAOpenMessageHeaderViewID";
}

@end
