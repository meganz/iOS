import Foundation

struct DevicePermissionCheckingProtocol {
    
    var getAlbumAuthorizationStatus: ((@escaping (PhotoAuthorization) -> Void)) -> Void

    var getAudioAuthorizationStatus: (@escaping (Bool) -> Void) -> Void

    var getVideoAuthorizationStatus: (@escaping (Bool) -> Void) -> Void
}

extension DevicePermissionCheckingProtocol {

    static var live: Self {
        Self.init(getAlbumAuthorizationStatus: { callback in
            PhotoPermission.live.request {
                callback($0)
            }
        }, getAudioAuthorizationStatus: { callback in
            DevicePermission.live.requestAudio {
                callback($0)
            }
        }, getVideoAuthorizationStatus: { callback in
            DevicePermission.live.requestVideo {
                callback($0)
            }
        })
    }
}
