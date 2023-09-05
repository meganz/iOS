#import "AVAudioSession+MNZCategory.h"

@implementation AVAudioSession (MNZCategory)

- (BOOL)mnz_isBluetoothAudioConnected {
    BOOL ret = NO;
    NSArray *outputs = AVAudioSession.sharedInstance.currentRoute.outputs;
    for (AVAudioSessionPortDescription *port in outputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP] ||
            [port.portType isEqualToString:AVAudioSessionPortBluetoothLE] ||
            [port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            ret = YES;
            break;
        }
    }
    
    MEGALogDebug(@"[AVAudioSession] Is there any bluetooth audio connected? %@", ret ? @"YES" : @"NO");
    return ret;
}

- (NSString *)stringForAVAudioSessionRouteChangeReason:(AVAudioSessionRouteChangeReason)reason {
    NSString *ret;
    switch (reason) {
        case AVAudioSessionRouteChangeReasonUnknown:
            ret = @"Unknow";
            break;
        
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            ret = @"New device available";
            break;
        
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            ret = @"Old device unavailable";
            break;
        
        case AVAudioSessionRouteChangeReasonCategoryChange:
            ret = @"Category change";
            break;
        
        case AVAudioSessionRouteChangeReasonOverride:
            ret = @"Override";
            break;
        
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            ret = @"Wake from sleep";
            break;
        
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            ret = @"Suitable route for category";
            break;
        
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            ret = @"Route configuration change";
            break;
            
        default:
            ret = @"Default";
            break;
    }
    
    return ret;
}

@end
