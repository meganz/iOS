#import "UIImageView+WMLTemplatedAnimation.h"

static NSString *const WMLTemplatedAnimationColorFillLayerName = @"WMLTemplatedAnimationFillLayerName";
static NSString *const WMLTemplatedAnimationMaskLayerName = @"WMLTemplatedAnimationMaskLayerName";

@implementation UIImageView (WMLTemplatedAnimation)

- (void)wml_startAnimating {
    if ([self isAnimating]) {
        return;
    }
    
    NSArray *animationImages = [self isHighlighted] && self.highlightedAnimationImages ? self.highlightedAnimationImages : self.animationImages;
    UIImage *probeImage = [animationImages firstObject];
    if (probeImage.renderingMode != UIImageRenderingModeAlwaysTemplate) {
        [self startAnimating];
        return;
    }
    
    CGSize imageSize = probeImage.size;
    self.frame = ({
        CGRect frame = self.frame;
        frame.size = imageSize;
        frame;
    });
    NSMutableArray *cgAnimationImages = [NSMutableArray arrayWithCapacity:[animationImages count]];
    for (UIImage *image in animationImages) {
        [cgAnimationImages addObject:(__bridge id)[image CGImage]];
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"contents";
    animation.values = cgAnimationImages;
    animation.calculationMode = kCAAnimationDiscrete;
    animation.duration = self.animationDuration ?: 1.633;
    animation.repeatCount = self.animationRepeatCount != 0 ?: HUGE_VALF;
    animation.removedOnCompletion = self.animationRepeatCount < 1;
    animation.delegate = [self valueForKey:@"_storage"];
    
    self.layer.contents = nil;

    CALayer *tintColorLayer = [self wml_layerForName:WMLTemplatedAnimationColorFillLayerName];
    if (!tintColorLayer) {
        tintColorLayer = [CALayer layer];
        tintColorLayer.name = WMLTemplatedAnimationColorFillLayerName;
        tintColorLayer.frame = self.layer.bounds;
        tintColorLayer.transform = self.layer.transform;
        tintColorLayer.contents = nil;
    }
    tintColorLayer.backgroundColor = [self.tintColor CGColor];

    CALayer *mask = [self wml_layerForName:WMLTemplatedAnimationMaskLayerName];
    if (!mask) {
        mask = [CALayer layer];
        mask.name = WMLTemplatedAnimationMaskLayerName;
        mask.frame = self.layer.bounds;
        mask.transform = self.layer.transform;
        tintColorLayer.mask = mask;
    }

    [mask addAnimation:animation forKey:@"contents"];
    [self.layer addSublayer:tintColorLayer];

    // TODO: this triggers regular startAnimating
    [self setValue:@YES forKey:@"animating"];
}

- (void)wml_stopAnimating {
    if (![self isAnimating]) {
        return;
    }

    CALayer *colorFillLayer = [self wml_layerForName:WMLTemplatedAnimationColorFillLayerName];
    [colorFillLayer removeFromSuperlayer];

    [self stopAnimating];
}

- (CALayer *)wml_layerForName:(NSString *)name {
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.name isEqualToString:name]) {
            return layer;
        }
    }
    return nil;
}

@end
