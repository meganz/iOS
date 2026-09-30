#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Swaps method implementations at runtime, for crash protection only
@interface MNZMethodSwizzler : NSObject

/// Exchanges the implementations of `originalSelector` and `swizzledSelector` on `cls` itself.
///
/// @return `NO`, changing nothing, when `cls` is Nil, either selector is missing, or their signatures differ.
+ (BOOL)swizzleInstanceMethod:(SEL)originalSelector
                   withMethod:(SEL)swizzledSelector
                      inClass:(nullable Class)cls;

@end

NS_ASSUME_NONNULL_END
