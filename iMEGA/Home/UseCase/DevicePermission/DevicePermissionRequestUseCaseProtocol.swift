import Foundation

typealias PhotoAlbumPermissionRequestResult = Result<PhotoAuthorization, DevicePermissionDeniedError>
typealias DevicePermissionRequestResult     = Result<Void, DevicePermissionDeniedError>

protocol DevicePermissionRequestUseCaseProtocol {

    /// Request device's `Photos` access to load photos.
    /// - Parameter completion: A completion handler that will handle a result of `PhotoAuthorization` or a
    /// `DevicePermissionDeniedError`.
    ///  If `.authorized` or `.limited`, then the reuslt will be `.success(.authorized)` or `.success(.limited)`
    ///  If denied, the result will be `.failure(.photos)`
    func requestAlbumAccess(completion: @escaping (PhotoAlbumPermissionRequestResult) -> Void)

    /// Request device's `Audio` access to load photos.
    /// - Parameter completion: A completion handler that will handle a result of granting the access or a
    /// `DevicePermissionDeniedError`.
    ///  If permission granted, then the reuslt will be `.success`
    ///  If denied, the result will be `.failure(.audio)`
    func requestAudioAccess(completion: @escaping (DevicePermissionRequestResult) -> Void)

    /// Request device's `Camera` access to load photos.
    /// - Parameter completion: A completion handler that will handle a result of granting the access or a `DevicePermissionDeniedError`.
    ///  If permission granted, then the reuslt will be `.success`
    ///  If denied, the result will be `.failure(.video)`
    func requestVideoAccess(completion: @escaping (DevicePermissionRequestResult) -> Void)
}

struct DevicePermissionRequestUseCase: DevicePermissionRequestUseCaseProtocol {

    private let photoPermission: PhotoPermission

    private let devicePermission: DevicePermission

    init(
        photoPermission: PhotoPermission,
        devicePermission: DevicePermission
    ) {
        self.photoPermission = photoPermission
        self.devicePermission = devicePermission
    }

    // MARK: - DevicePermissionRequestUseCase

    func requestAlbumAccess(completion: @escaping (PhotoAlbumPermissionRequestResult) -> Void) {
        photoPermission.request { authorizationStatus in
           switch authorizationStatus {
           case .authorized: completion(.success(.authorized))
           case .limited:
                completion(.success(.limited))
           default: completion(.failure(.photos))
           }
       }
    }

    func requestAudioAccess(completion: @escaping (DevicePermissionRequestResult) -> Void) {
        devicePermission.requestAudio { permissionGranted in
            guard permissionGranted else {
                completion(.failure(.audio))
                return
            }
            completion(.success(()))
        }
    }

    func requestVideoAccess(completion: @escaping (DevicePermissionRequestResult) -> Void) {
        devicePermission.requestVideo { permissionGranted in
            guard permissionGranted else {
                completion(.failure(.video))
                return
            }
            completion(.success(()))
        }
    }
}
