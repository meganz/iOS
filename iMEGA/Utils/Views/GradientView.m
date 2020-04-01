#import "GradientView.h"

@implementation GradientView

+ (Class) layerClass {
    return [CAGradientLayer class];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    CAGradientLayer *gradientLayer = (CAGradientLayer*)self.layer;
    gradientLayer.colors = @[
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] CGColor],
        (id)[[UIColor colorWithRed:1 green:1 blue:1 alpha:0] CGColor],
        (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] CGColor]
    ];
    gradientLayer.locations = @[@(0), @(0.5), @(1)];
    gradientLayer.startPoint = CGPointMake(0.5, 0);
    gradientLayer.endPoint = CGPointMake(0.5, 1);
}

@end
