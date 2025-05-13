#import "CopyableLabel.h"
#import "MEGA-Swift.h"

@implementation CopyableLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    self.userInteractionEnabled = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self showHideEditMenu];
}

@end
