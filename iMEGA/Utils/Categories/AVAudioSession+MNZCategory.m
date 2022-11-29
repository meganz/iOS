
#import "AVAudioSession+MNZCategory.h"

@implementation AVAudioSession (MNZCategory)

- (BOOL)mnz_isOutputEqualToPortType:(AVAudioSessionPort)portType {
    BOOL ret = NO;
    if (AVAudioSession.sharedInstance.currentRoute.outputs.count > 0) {
        AVAudioSessionPortDescription *audioSessionPortDestription = AVAudioSession.sharedInstance.currentRoute.outputs.firstObject;
        if ([audioSessionPortDestription.portType isEqualToString:portType]) {
            ret = YES;
        }
    } else {
        MEGALogWarning(@"[AVAudioSession] Array of audio outputs is empty");
    }
    
    MEGALogDebug(@"[AVAudioSession] Is the output equal to %@? %@", portType, ret ? @"YES" : @"NO");
    return ret;
}

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

- (BOOL)mnz_isBluetoothAudioRouteAvailable {
    __block BOOL isBluetoothAudioRouteAvailable = NO;
    [AVAudioSession.sharedInstance.availableInputs enumerateObjectsUsingBlock:^(AVAudioSessionPortDescription *description, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([@[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP] containsObject:description.portType]) {
            isBluetoothAudioRouteAvailable = YES;
            *stop = YES;
        }
    }];
    
    MEGALogDebug(@"[AVAudioSession] Is there any bluetooth audio available? %@", isBluetoothAudioRouteAvailable ? @"YES" : @"NO");
    return isBluetoothAudioRouteAvailable;
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
