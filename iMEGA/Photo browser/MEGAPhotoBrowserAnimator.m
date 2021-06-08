
#import "MEGAPhotoBrowserAnimator.h"

@interface MEGAPhotoBrowserAnimator ()

@property (nonatomic) MEGAPhotoBrowserAnimatorMode mode;
@property (nonatomic) CGRect originFrame;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) UIImageView *targetImageView;

@end

@implementation MEGAPhotoBrowserAnimator

#pragma mark - Initialization

- (instancetype)initWithMode:(MEGAPhotoBrowserAnimatorMode)mode originFrame:(CGRect)originFrame targetImageView:(UIImageView *)targetImageView {
    if (self = [super init]) {
        _mode = mode;
        _originFrame = originFrame;
        _duration = 0.2;
        _targetImageView = targetImageView;
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
            UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
            CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
            CGAffineTransform scaleTransform = [self transformForFrame:finalFrame];
            
            targetView.transform = scaleTransform;
            targetView.center = originCenterPoint;
            targetView.clipsToBounds = YES;
            
            [transitionView addSubview:targetView];
            
            [UIView animateWithDuration:self.duration
                             animations:^{
                targetView.transform = CGAffineTransformIdentity;
                targetView.center = [self centerPointForFrame:finalFrame];
                [targetView setFrame:finalFrame];
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
            }];
            
            break;
        }
            
        case MEGAPhotoBrowserAnimatorModeDismiss: {
            CGRect finalFrame = self.targetImageView.frame;
            CGAffineTransform scaleTransform = [self transformForFrame:finalFrame];

            self.targetImageView.transform = CGAffineTransformIdentity;
            self.targetImageView.center = [self centerPointForFrame:finalFrame];
            self.targetImageView.clipsToBounds = YES;
            
            [transitionView addSubview:self.targetImageView];
            
            [UIView animateWithDuration:self.duration
                             animations:^{
                                 self.targetImageView.transform = scaleTransform;
                                 self.targetImageView.center = originCenterPoint;
                                 self.targetImageView.frame = self.originFrame;
                                 self.targetImageView.contentMode = UIViewContentModeScaleAspectFill;
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
    return CGAffineTransformMakeScale(xFactor, xFactor);
}

- (CGPoint)originCenterPoint {
    return [self centerPointForFrame:self.originFrame];
}

- (CGPoint)centerPointForFrame:(CGRect)frame {
    return CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
}

@end
