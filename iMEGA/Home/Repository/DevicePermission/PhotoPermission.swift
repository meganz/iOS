import Foundation

struct PhotoPermission {

    var request: (
        _ photoAlbumAuthorizationRequestCompletion: @escaping (PhotoAuthorization) -> Void
    ) -> Void
}

extension PhotoPermission {

    static var live: PhotoPermission {
        return Self { completion in
            let photoLibraryCallback: (PHAuthorizationStatus) -> Void = { authorization in
                DispatchQueue.main.async {
                    completion(PhotoAuthorization(with: authorization) ?? .unknown)
                }
            }

            PHPhotoLibrary.requestAuthorization(photoLibraryCallback)
        }
    }
}

enum PhotoAuthorization: Int {
    case notDetermined      = 0 // User has not yet made a choice with regards to this application
    case restricted         = 1 // This application is not authorized to access photo data.
    case denied             = 2 // User has explicitly denied this application access to photos data.
    case authorized         = 3 // User has authorized this application to access photos data.
    case limited            = 4 // User has authorized this application for limited photo library access.
    case unknown

    init?(with authorization: PHAuthorizationStatus) {
        self.init(rawValue: authorization.rawValue)
    }
}
