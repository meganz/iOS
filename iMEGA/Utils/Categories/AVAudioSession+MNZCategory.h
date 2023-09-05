#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAudioSession (MNZCategory)

/** @brief Returns YES if there is a bluetooth audio connected.
 *
 * @return YES if there is a bluetooth audio connected, otherwise NO.
 */
@property (nonatomic, readonly, getter=mnz_isBluetoothAudioConnected) BOOL mnz_BluetoothAudioConnected;

/** @brief Convert AVAudioSessionRouteChangeReason to string.
*
* @param reason the AVAudioSessionRouteChangeReason reason.
* @return string for a AVAudioSessionRouteChangeReason reason.
*/
- (NSString *)stringForAVAudioSessionRouteChangeReason:(AVAudioSessionRouteChangeReason)reason;

@end

NS_ASSUME_NONNULL_END
