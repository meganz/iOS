public protocol CaptureDeviceUseCaseProtocol: Sendable {
    func wideAngleCameraLocalizedName(position: CameraPositionEntity) -> String?
}

public struct CaptureDeviceUseCase<T: CaptureDeviceRepositoryProtocol>: CaptureDeviceUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func wideAngleCameraLocalizedName(position: CameraPositionEntity) -> String? {
        repo.wideAngleCameraLocalizedName(position: position)
    }
}
