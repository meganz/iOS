
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (MNZCategory)

- (void)mnz_startShimmering;
- (void)mnz_stopShimmering;
- (nullable UITapGestureRecognizer *)mnz_firstTapGestureWithNumberOfTaps:(NSUInteger)taps;
- (BOOL)recursivelyFindSubview:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
