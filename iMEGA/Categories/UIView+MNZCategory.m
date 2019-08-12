
#import "UIView+MNZCategory.h"

@implementation UIView (MNZCategory)

- (void)mnz_startShimmering {
    id light = (id)[UIColor colorWithWhite:0.82 alpha:0.1].CGColor;
    id dark = (id)[UIColor colorWithWhite:0.0 alpha:1].CGColor;
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[dark, light, dark];
    gradientLayer.frame = CGRectMake(-self.bounds.size.width, 0, 3*self.bounds.size.width, self.bounds.size.height);
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.525);
    gradientLayer.locations = @[@0.3, @0.5, @0.6];
    self.layer.mask = gradientLayer;

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
    animation.fromValue = @[@0.0, @0.1, @0.2];
    animation.toValue = @[@0.8, @0.9, @1.0];
    animation.duration = 1.5;
    animation.repeatCount = FLT_MAX;
    [gradientLayer addAnimation:animation forKey:@"shimmer"];
}

- (void)mnz_stopShimmering {
    self.layer.mask = nil;
}

- (nullable UITapGestureRecognizer *)mnz_firstTapGestureWithNumberOfTaps:(NSUInteger)taps {
    UITapGestureRecognizer *tapGesture;

    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]
            && ((UITapGestureRecognizer *)gestureRecognizer).numberOfTapsRequired == taps) {
            tapGesture = (UITapGestureRecognizer *)gestureRecognizer;
            break;
        }
    }
    
    return tapGesture;
}

@end
