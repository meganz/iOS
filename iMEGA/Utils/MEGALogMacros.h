
#import "MEGASdk.h"

#define MEGALogFatal(frmt, ...)   [MEGASdk logWithLevel:MEGALogLevelFatal message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
#define MEGALogError(frmt, ...)   [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
#define MEGALogWarning(frmt, ...) [MEGASdk logWithLevel:MEGALogLevelWarning message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
#define MEGALogInfo(frmt, ...)    [MEGASdk logWithLevel:MEGALogLevelInfo message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
#define MEGALogDebug(frmt, ...)   [MEGASdk logWithLevel:MEGALogLevelDebug message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
#define MEGALogMax(frmt, ...)     [MEGASdk logWithLevel:MEGALogLevelMax message:[NSString stringWithFormat:@"[iOS] "frmt, ##__VA_ARGS__] filename:[NSString stringWithFormat:@"%s", __FILE__] line:__LINE__];
