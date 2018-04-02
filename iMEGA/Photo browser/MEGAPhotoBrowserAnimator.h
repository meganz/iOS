
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MEGAPhotoBrowserAnimatorMode) {
    MEGAPhotoBrowserAnimatorModePresent = 0,
    MEGAPhotoBrowserAnimatorModeDismiss
};

@interface MEGAPhotoBrowserAnimator : NSObject <UIViewControllerAnimatedTransitioning>

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithMode:(MEGAPhotoBrowserAnimatorMode)mode originFrame:(CGRect)originFrame targetImageView:(UIImageView *)targetImageView;

@end
