
#import <UIKit/UIKit.h>

@interface UIDevice (MNZCategory)

/**
 * @brief YES if the style of interface to use should be designed for iPhone and iPod touch on the current device, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhoneDevice;

/**
 * @brief YES if the device is an iPhone 4 or 4S or and iPod (4th Generation), otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone4X;

/**
 * @brief YES if the device is an iPhone 5, 5C, 5S, SE + iPod (5th, 6th Generation), otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone5X;

/**
 * @brief YES if the device is an iPhone 6, 6S, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPhone6X;

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
 * @brief YES if the device is an iPad Pro 12.9-inch, otherwise NO.
 */
@property (nonatomic, readonly) BOOL iPadPro;

/**
 * @brief The max buffer for streaming, based on device RAM.
 */
@property (nonatomic, readonly) NSUInteger maxBufferSize;

- (NSString *)deviceName;
- (CGFloat)mnz_widthForChatBubble;

@end
