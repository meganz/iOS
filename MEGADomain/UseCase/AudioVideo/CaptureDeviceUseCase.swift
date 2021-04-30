
protocol CaptureDeviceUseCaseProtocol {
    func wideAngleCameraLocalizedName(postion: CameraPosition) -> String?
}

struct CaptureDeviceUseCase: CaptureDeviceUseCaseProtocol {
    private let repo: CaptureDeviceRepositoryProtocol
    
    init(repo: CaptureDeviceRepositoryProtocol) {
        self.repo = repo
    }
    
    func wideAngleCameraLocalizedName(postion: CameraPosition) -> String? {
        repo.wideAngleCameraLocalizedName(postion: postion)
    }
}
