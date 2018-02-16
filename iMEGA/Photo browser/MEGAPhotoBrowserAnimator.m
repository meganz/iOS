
#import "MEGAPhotoBrowserAnimator.h"

@interface MEGAPhotoBrowserAnimator ()

@property (nonatomic) MEGAPhotoBrowserAnimatorMode mode;
@property (nonatomic) CGRect originFrame;
@property (nonatomic) NSTimeInterval duration;

@end

@implementation MEGAPhotoBrowserAnimator

#pragma mark - Initialization

- (instancetype)initWithMode:(MEGAPhotoBrowserAnimatorMode)mode originFrame:(CGRect)originFrame {
    if (self = [super init]) {
        _mode = mode;
        _originFrame = originFrame;
        _duration = 0.2;
    }
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGPoint originCenterPoint = [self originCenterPoint];
    UIView *transitionView = transitionContext.containerView;

    switch (self.mode) {
        case MEGAPhotoBrowserAnimatorModePresent: {
            UIView *targetView = [transitionContext viewForKey:UITransitionContextToViewKey];
            
            CGRect finalFrame = targetView.frame;
            CGAffineTransform scaleTransform = [self transformForFrame:finalFrame];
            
            targetView.transform = scaleTransform;
            targetView.center = originCenterPoint;
            targetView.clipsToBounds = YES;
            
            [transitionView addSubview:targetView];
            
            [UIView animateWithDuration:self.duration
                             animations:^{
                                 targetView.transform = CGAffineTransformIdentity;
                                 targetView.center = [self centerPointForFrame:finalFrame];
                             } completion:^(BOOL finished) {
                                 [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                             }];
            
            break;
        }
            
        case MEGAPhotoBrowserAnimatorModeDismiss: {
            UIView *targetView = [transitionContext viewForKey:UITransitionContextFromViewKey];
            
            CGRect finalFrame = targetView.frame;
            CGAffineTransform scaleTransform = [self transformForFrame:finalFrame];

            targetView.transform = CGAffineTransformIdentity;
            targetView.center = [self centerPointForFrame:finalFrame];
            targetView.clipsToBounds = YES;
            
            [transitionView addSubview:targetView];
            
            [UIView animateWithDuration:self.duration
                             animations:^{
                                 targetView.transform = scaleTransform;
                                 targetView.center = originCenterPoint;
                             } completion:^(BOOL finished) {
                                 [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
                             }];

            break;
        }
    }
}

#pragma mark - Private

- (CGAffineTransform)transformForFrame:(CGRect)frame {
    CGFloat xFactor = self.originFrame.size.width / frame.size.width;
    CGFloat yFactor = xFactor * self.originFrame.size.height / self.originFrame.size.width;
    return CGAffineTransformMakeScale(xFactor, yFactor);
}

- (CGPoint)originCenterPoint {
    return CGPointMake(self.originFrame.origin.x + self.originFrame.size.width*0.5, self.originFrame.origin.y + self.originFrame.size.height*0.5);
}

- (CGPoint)centerPointForFrame:(CGRect)frame {
    return CGPointMake(frame.origin.x + frame.size.width*0.5, frame.origin.y + frame.size.height*0.5);
}

@end
