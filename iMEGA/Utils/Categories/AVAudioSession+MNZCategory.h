
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (MNZCategory)

/** @brief Returns YES if there is a bluetooth audio connected.
 *
 * @return YES if there is a bluetooth audio connected, otherwise NO.
 */
@property (nonatomic, readonly, getter=mnz_isBluetoothAudioConnected) BOOL mnz_BluetoothAudioConnected;

/** @brief Returns YES if there is a bluetooth route available.
*
* @return YES if there is a bluetooth route available, otherwise NO.
*/
@property (nonatomic, readonly, getter=mnz_isBluetoothAudioRouteAvailable) BOOL mnz_isBluetoothAudioRouteAvailable;

/** @brief Check if the first object in the current route outputs match with the type used as parameter, otherwise NO.
 *
 * @param portType the av audio session port type to check with.
 * @return YES if the first objects of the current route outputs match with the type, otherwise NO.
 */
- (BOOL)mnz_isOutputEqualToPortType:(AVAudioSessionPort)portType;

/** @brief Convert AVAudioSessionRouteChangeReason to string.
*
* @param reason the AVAudioSessionRouteChangeReason reason.
* @return string for a AVAudioSessionRouteChangeReason reason.
*/
- (NSString *)stringForAVAudioSessionRouteChangeReason:(AVAudioSessionRouteChangeReason)reason;

@end

NS_ASSUME_NONNULL_END
