
protocol CaptureDeviceUseCaseProtocol {
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String?
}

struct CaptureDeviceUseCase<T: CaptureDeviceRepositoryProtocol>: CaptureDeviceUseCaseProtocol {
    private let repo: T
    
    init(repo: T) {
        self.repo = repo
    }
    
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        repo.wideAngleCameraLocalizedName(postion: postion)
    }
}
