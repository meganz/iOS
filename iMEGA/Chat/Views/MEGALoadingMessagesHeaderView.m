#import "MEGALoadingMessagesHeaderView.h"

@implementation MEGALoadingMessagesHeaderView

+ (UINib *)nib {
    return [UINib nibWithNibName:@"MEGALoadingMessagesHeaderView" bundle:nil];
}

+ (NSString *)headerReuseIdentifier {
    return @"MEGALoadingMessagesHeaderViewID";
}

@end
