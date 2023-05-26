
public protocol CaptureDeviceUseCaseProtocol {
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String?
}

public struct CaptureDeviceUseCase<T: CaptureDeviceRepositoryProtocol>: CaptureDeviceUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        repo.wideAngleCameraLocalizedName(postion: postion)
    }
}
