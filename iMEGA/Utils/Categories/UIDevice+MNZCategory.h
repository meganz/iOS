
#import <UIKit/UIKit.h>

@interface UIDevice (MNZCategory)

/**
 * @brief YES if the style of interface to use should be designed for iPhone and iPod touch on the current device, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhoneDevice;

/**
 * @brief YES if the device is an iPhone 6 Plus, 6S Plus otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone6XPlus;

/**
 * @brief YES if the device is an iPhone 7 Plus, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone7Plus;

/**
 * @brief YES if the device is an iPhone 8 Plus, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone8Plus;

/**
 * @brief YES if the device is an iPhone 6 Plus, 6S Plus, 7 Plus, 8 Plus, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhonePlus;
    
/**
 * @brief YES if the device is an iPhone X, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhoneX;

/**
 * @brief YES if the style of interface to use should be designed for iPad on the current device, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPadDevice;

/**
 * @brief YES if the device is an iPad (3rd, 4th Generation), iPad Air (5th Generation), iPad Pro (9.7-inch), iPad mini (2nd, 3rd Generation), otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPad;

/**
 * @brief YES if the device is an iPad mini, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPadMini;

/**
 * @brief The max buffer for streaming, based on device RAM.
 */
@property (nonatomic, readonly) NSUInteger maxBufferSize;

- (NSString *)deviceName;
- (CGFloat)mnz_maxSideForChatBubbleWithMedia:(BOOL)media;

@end
