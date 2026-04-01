@testable import MEGA
import Testing

struct CameraUploadQueueStatesTests {

    struct Photos {
        @Test(arguments: [
            (CameraUploadQueueState.background,        1),
            (.lowPowerMode,                            2),
            (.batteryCharging,                         4),
            (.batteryLevel(.above75),                  4),
            (.batteryLevel(.below75),                  4),
            (.batteryLevel(.below55),                  3),
            (.batteryLevel(.below40),                  2),
            (.batteryLevel(.below25),                  1),
            (.batteryLevel(.below15),                  0),
            (.thermalState(.fair),                     3),
            (.thermalState(.serious),                  1),
            (.thermalState(.critical),                 0),
            (.defaultMaximum,                          4)
        ] as [(CameraUploadQueueState, Int)])
        func readsFromPhotoUploadState(photoState: CameraUploadQueueState, expected: Int) {
            let states = CameraUploadQueueStates(
                photoUploadState: photoState,
                videoUploadState: .thermalState(.critical)
            )
            #expect(states.photoConcurrentCount == expected)
        }
        
        @Test(arguments: [
            (CameraUploadQueueState.background,        Optional<CameraUploadMediaTypePausedReason>.none),
            (.lowPowerMode,                            .none),
            (.batteryCharging,                         .none),
            (.batteryLevel(.above75),                  .none),
            (.batteryLevel(.below75),                  .none),
            (.batteryLevel(.below55),                  .none),
            (.batteryLevel(.below40),                  .none),
            (.batteryLevel(.below25),                  .none),
            (.batteryLevel(.below15),                  .some(.lowBattery)),
            (.thermalState(.fair),                     .none),
            (.thermalState(.serious),                  .none),
            (.thermalState(.critical),                 .some(.thermalState(.critical))),
            (.defaultMaximum,                          .none)
        ] as [(CameraUploadQueueState, CameraUploadMediaTypePausedReason?)])
        func readsFromPhotoUploadState(photoState: CameraUploadQueueState, expected: CameraUploadMediaTypePausedReason?) {
            let states = CameraUploadQueueStates(
                photoUploadState: photoState,
                videoUploadState: .thermalState(.critical)
            )
            #expect(states.photoPausedReason == expected)
        }
    }

    struct Videos {
        @Test(arguments: [
            (CameraUploadQueueState.background,        1),
            (.lowPowerMode,                            1),
            (.batteryCharging,                         1),
            (.batteryLevel(.above75),                  1),
            (.batteryLevel(.below75),                  1),
            (.batteryLevel(.below55),                  1),
            (.batteryLevel(.below40),                  1),
            (.batteryLevel(.below25),                  1),
            (.batteryLevel(.below15),                  0),
            (.thermalState(.fair),                     1),
            (.thermalState(.serious),                  0),
            (.thermalState(.critical),                 0),
            (.defaultMaximum,                          1)
        ] as [(CameraUploadQueueState, Int)])
        func readsFromVideoUploadState(videoState: CameraUploadQueueState, expected: Int) {
            let states = CameraUploadQueueStates(
                photoUploadState: .background,
                videoUploadState: videoState
            )
            #expect(states.videoConcurrentCount == expected)
        }
        
        @Test(arguments: [
            (CameraUploadQueueState.background,        Optional<CameraUploadMediaTypePausedReason>.none),
            (.lowPowerMode,                            .none),
            (.batteryCharging,                         .none),
            (.batteryLevel(.above75),                  .none),
            (.batteryLevel(.below75),                  .none),
            (.batteryLevel(.below55),                  .none),
            (.batteryLevel(.below40),                  .none),
            (.batteryLevel(.below25),                  .none),
            (.batteryLevel(.below15),                  .some(.lowBattery)),
            (.thermalState(.fair),                     .none),
            (.thermalState(.serious),                  .some(.thermalState(.serious))),
            (.thermalState(.critical),                 .some(.thermalState(.critical))),
            (.defaultMaximum,                          .none)
        ] as [(CameraUploadQueueState, CameraUploadMediaTypePausedReason?)])
        func readsFromVideoUploadState(videoState: CameraUploadQueueState, expected: CameraUploadMediaTypePausedReason?) {
            let states = CameraUploadQueueStates(
                photoUploadState: .background,
                videoUploadState: videoState
            )
            #expect(states.videoPausedReason == expected)
        }
    }
}
