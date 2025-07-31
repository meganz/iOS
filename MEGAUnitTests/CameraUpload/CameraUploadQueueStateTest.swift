@testable import MEGA
import Testing

struct CameraUploadQueueStateTests {
    @Test(arguments: [
        (CameraUploadQueueState.background, 1),
        (.lowPowerMode, 2),
        (.batteryCharging, 4),
        (.batteryLevel(.above75), 4),
        (.batteryLevel(.below75), 4),
        (.batteryLevel(.below40), 2),
        (.batteryLevel(.below25), 1),
        (.batteryLevel(.below15), 0),
        (.thermalState(.fair), 3),
        (.thermalState(.serious), 1),
        (.thermalState(.critical), 0),
        (.defaultMaximum, 4)
    ])
    func photoConcurrentCount(state: CameraUploadQueueState, expectedCount: Int) {
        #expect(state.photoConcurrentCount == expectedCount)
    }
    
    @Test(arguments: [
        (CameraUploadQueueState.background, Optional<CameraUploadMediaTypePausedReason>.none),
        (.lowPowerMode, .none),
        (.batteryCharging, .none),
        (.batteryLevel(.above75), .none),
        (.batteryLevel(.below75), .none),
        (.batteryLevel(.below40), .none),
        (.batteryLevel(.below25), .none),
        (.batteryLevel(.below15), .some(.lowBattery)),
        (.thermalState(.fair), .none),
        (.thermalState(.serious), .none),
        (.thermalState(.critical), .some(.thermalState(.critical))),
        (.defaultMaximum, .none)
    ])
    func photoPausedReason(state: CameraUploadQueueState, reason: CameraUploadMediaTypePausedReason?) {
        #expect(state.photoPausedReason == reason)
    }
    
    @Test(arguments: [
        (CameraUploadQueueState.background, 1),
        (.lowPowerMode, 1),
        (.batteryCharging, 1),
        (.batteryLevel(.above75), 1),
        (.batteryLevel(.below75), 1),
        (.batteryLevel(.below40), 1),
        (.batteryLevel(.below25), 1),
        (.batteryLevel(.below15), 0),
        (.thermalState(.fair), 1),
        (.thermalState(.serious), 0),
        (.thermalState(.critical), 0),
        (.defaultMaximum, 1)
    ])
    func videoConcurrentCount(state: CameraUploadQueueState, expectedCount: Int) {
        #expect(state.videoConcurrentCount == expectedCount)
    }
    
    @Test(arguments: [
        (CameraUploadQueueState.background, Optional<CameraUploadMediaTypePausedReason>.none),
        (.lowPowerMode, .none),
        (.batteryCharging, .none),
        (.batteryLevel(.above75), .none),
        (.batteryLevel(.below75), .none),
        (.batteryLevel(.below40), .none),
        (.batteryLevel(.below25), .none),
        (.batteryLevel(.below15), .some(.lowBattery)),
        (.thermalState(.fair), .none),
        (.thermalState(.serious), .some(.thermalState(.serious))),
        (.thermalState(.critical), .some(.thermalState(.critical))),
        (.defaultMaximum, .none)
    ])
    func videoPausedReason(state: CameraUploadQueueState, reason: CameraUploadMediaTypePausedReason?) {
        #expect(state.videoPausedReason == reason)
    }
}
