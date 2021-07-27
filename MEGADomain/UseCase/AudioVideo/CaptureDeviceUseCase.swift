
protocol CaptureDeviceUseCaseProtocol {
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String?
}

struct CaptureDeviceUseCase: CaptureDeviceUseCaseProtocol {
    private let repo: CaptureDeviceRepositoryProtocol
    
    init(repo: CaptureDeviceRepositoryProtocol) {
        self.repo = repo
    }
    
    func wideAngleCameraLocalizedName(postion: CameraPositionEntity) -> String? {
        repo.wideAngleCameraLocalizedName(postion: postion)
    }
}
