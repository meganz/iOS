#import "CameraUploadOperation.h"
#import "MEGA-Swift.h"

NS_ASSUME_NONNULL_BEGIN

/// Telemetry state of an upload operation. Kept out of CameraUploadOperation.h, which the bridging header imports and
/// therefore can't use types generated from Swift.
@interface CameraUploadOperation ()

/// The step the operation is in, reported if it fails. Set through enterTelemetryStep: once processing starts.
@property (nonatomic) CameraUploadTelemetryStep telemetryStep;

/// Moves the operation to a step and the matching pipeline stage.
- (void)enterTelemetryStep:(CameraUploadTelemetryStep)step;

/// Like finishOperationWithStatus:, with the error that caused a failure.
- (void)finishOperationWithStatus:(CameraAssetUploadStatus)status error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
